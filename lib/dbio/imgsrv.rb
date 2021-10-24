# coding: utf-8
require "json"
require "sequel"
require "date"
require "digest"
require "open-uri"
require "date"
require "net/http"
require "fastimage"

class ImageServer
  attr_reader :config, :db

  def initialize(config, db)
    @config = config
    @db = db
  end

  def search(params)
    img_url_path = @config["app"]["img_url_path"]

    recs = @db[:images].join_table(:inner, :image_tags, url_hash: :url_hash)
    cnt = 0

    tag_cnt = (params[:tags] || []).size
    if tag_cnt > 0
      if params[:type] == :and
        recs = recs
          .where(tag: params[:tags])
          .group(Sequel[:images][:url_hash])
          .having(Sequel.lit("count(images.url_hash) >= #{tag_cnt}"))
      else
        recs = recs
          .where(tag: params[:tags])
          .group(Sequel[:images][:url_hash])
          .having(Sequel.lit("count(images.url_hash) >= 1"))
      end
    else
      recs = recs
        .group(Sequel[:images][:url_hash])
        .having(Sequel.lit("count(images.url_hash) >= 1"))
    end
    cnt = recs
      .select { count(Sequel[:images][:url_hash]) { }.as(count) }
      .to_a
      .size
    page_size = (cnt / params[:limit].to_f).ceil
    offset = params[:offset]
    page = params[:page].to_i
    if page > page_size
      return {
               status: 400,
               msg: "invalid offset: offset > page size",
               page: page,
               page_size: page_size,
             }
    end
    sortkey = Sequel.desc(Sequel[:images][params[:sort]])
    if params[:order] == :asc
      sortkey = Sequel.asc(Sequel[:images][params[:sort]])
    end
    recs = recs
      .order(sortkey)
      .limit(params[:limit])
      .offset(params[:offset])
      .to_a
      .map { |r|
      fn = r[:url_hash]
      fn += "." + r[:ext] if r[:ext]
      {
        url: img_url_path + fn,
        tags: @db[:image_tags].where(url_hash: r[:url_hash]).to_a.map { |u| u[:tag] },
        bytesize: r[:bytesize],
        width: r[:width],
        height: r[:height],
        source_url: r[:source_url],
        created_at: r[:created_at],
      }
    }

    {
      data: recs,
      count: cnt,
      page_size: page_size,
      page: params[:page],
      limit: params[:limit],
      offset: offset,
    }
  end

  def save_img(url, save_name, ext)
    img_path = @config["app"]["img_path"]
    u = URI.parse(url)
    fp = "#{img_path}#{save_name}.#{ext}"
    Net::HTTP.start(u.host) do |http|
      resp = http.get(u.path)
      open(fp, "wb") do |file|
        file.write(resp.body)
      end
    end
    width, height = FastImage.size(fp)
    {
      bytesize: File.size(fp),
      width: width,
      height: height,
    }
  end

  def post(params)
    img_url_path = @config["app"]["img_url_path"]
    nowf = DateTime.now.strftime("%Y/%m/%d %H:%M:%S")
    params["urls"].select { |x| x.size > 0 }.each do |data|
      url = data["url"]
      img_tags_ins_list = []

      hs = Digest::SHA1.hexdigest(url)

      ext = /^[a-z|A-Z]+/.match(URI.parse(url).path.split(".").last).to_a[0]

      next if File.exists?(img_url_path + hs + "." + (ext || ""))

      info = save_img(url, hs, ext)
      info[:url_hash] = hs
      info[:ext] = ext
      info[:created_at] = nowf
      info[:source_url] = url

      @db[:images].insert(info)
      puts "inserted image: #{url}"
      params["tags"].each do |tag|
        img_tags_ins_list << { url_hash: hs, tag: tag, created_at: nowf }
      end
      @db[:image_tags].multi_insert(img_tags_ins_list)
    end
  end

  # DBから画像を再取得する。
  # cont=true ... 取得できなかった画像があっても継続
  # cont=false ... 取得できなかった画像があれば停止
  def restore_img(cont = true)
    img_url_path = @config["app"]["img_url_path"]
    urls = @db[:images].to_a.map { |x| x[:source_url] }
    urls.select { |x| x.size > 0 }.each do |url|
      begin
        hs = Digest::SHA1.hexdigest(url)
        ext = /^[a-z|A-Z]+/.match(URI.parse(url).path.split(".").last).to_a[0]

        next if File.exists?(img_url_path + hs + "." + (ext || ""))

        info = save_img(url, hs, ext)
        hs = Digest::SHA1.hexdigest(url)
        ext = /^[a-z|A-Z]+/.match(URI.parse(url).path.split(".").last).to_a[0]

        next if File.exists?(img_url_path + hs + "." + (ext || ""))

        info = save_img(url, hs, ext)
      rescue
        unless cont
          return false
        end
      end
    end
    return true
  end
end
