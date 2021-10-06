# coding: utf-8
require 'sinatra'
require 'sinatra/reloader'
require 'json'
require 'sequel'
require 'mysql2'
require 'digest'
require 'open-uri'
require 'date'
require 'net/http'
require 'nokogiri'
require 'base64'
require 'fastimage'
require 'cgi'
require 'benchmark'

CONFIG = JSON.parse(File.read('./config.json'))

configure do
  set :bind, '0.0.0.0'
  register Sinatra::Reloader
  also_reload "./*.rb"
end

DB = Sequel.mysql2(
  host: CONFIG['db']['host'],
  user: CONFIG['db']['user'],
  password: CONFIG['db']['pass'],
  database: CONFIG['db']['name'],
  encoding: 'utf8'
)

$top = DB[:images].order(Sequel.desc(:created_at)).limit(20)

def save_img(url, save_name, ext)
  img_path = CONFIG['app']['img_path']
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

get '/' do
  erb :index
end

get '/post' do
  erb :post
end

get '/api/v1/img/in/page' do
  url = params['url']
  uri = URI.encode_www_form_component(url, enc=nil)
  uri = uri.gsub(/%3A/, ':').gsub(/%2F/, '/')
  doc = Nokogiri::HTML(URI.open(uri))
  imgs = []

  u = URI.parse(uri)
  hostsc = "#{u.scheme}://#{u.host}"
  doc.css('img').each do |img|
    src = img.attr('src')
    if src =~ /^\//
      src = "#{hostsc}#{src}"
    elsif !((src =~ /^.*?:\/\//) || (src =~ /^\//))
      src = "#{hostsc}#{u.path}#{src}"
      puts src
    end
    imgs << src
  end
  imgs.uniq.to_json
end

get '/api/v1/images/top' do
  img_url_path = CONFIG['app']['img_url_path']
  $top.to_a.map{ |r| {
                   url: img_url_path + r[:url_hash] + '.' + r[:ext],
                   tags: DB[:image_tags].where(url_hash: r[:url_hash]).to_a.map{ |u| u[:tag]},
                   bytesize: r[:bytesize],
                   width: r[:width],
                   height: r[:height],
                   source_url: r[:source_url],
                   created_at: r[:created_at],
                 }}.to_json
end

def parse_search_params(params)
  tags = params["tags"]
  # sort key.
  sort = params["sort"]
  # sort type(asc or desc)
  order = params[:order]
  page = params["page"]
  limit = params["limit"]
  tp = params["type"]

  # 現状はこのkeyだけsupport
  sort = :created_at

  if ['desc', 'asc'].include?(order)
    order = order.to_sym
  else
    order = :asc
  end

  unless page && page =~ /[0-9]+/ && page.to_i >= 1
    page = 1
  end
  unless limit && limit =~ /[0-9]+/ && limit.to_i >= 10
    limit = 10
  end
  offset = (page.to_i - 1) * limit.to_i

  if ['and', 'or'].include?(tp)
    tp = tp.to_sym
  else
    tp = :and
  end
  {
    page: page,
    tags: tags,
    sort: sort,
    order: order,
    offset: offset,
    limit: limit,
    type: tp,
  }
end

get '/api/v1/images/search' do
  pms = JSON.parse(params.to_json)
  params = parse_search_params(pms)

  img_url_path = CONFIG['app']['img_url_path']

  recs = DB[:images].join_table(:inner, :image_tags, url_hash: :url_hash)
  cnt = 0

  tag_cnt = (params[:tags]||[]).size
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
          .select{count(Sequel[:images][:url_hash]){}.as(count)}
          .to_a
          .size
  page_size = (cnt / params[:limit].to_f).ceil
  offset = params[:offset]
  page = params[:page].to_i
  if page > page_size
    return {
      status: 400,
      msg: 'invalid offset: offset > page size',
      page: page,
      page_size: page_size,
    }.to_json
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
           .map{ |r|
    fn = r[:url_hash]
    fn += '.' + r[:ext] if r[:ext]
    {
      url: img_url_path + fn,
      tags: DB[:image_tags].where(url_hash: r[:url_hash]).to_a.map{ |u| u[:tag]},
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
    status: 200,
  }.to_json
end

post '/api/v1/images' do
  img_url_path = CONFIG['app']['img_url_path']
  content_type :json
  rst = {
    status: 200,
    msg: "success",
  }
  params = JSON.parse request.body.read

  unless params['urls'].size > 0
    rst[:status] = 400
    rst[:msg] = "not data"
    return rst.to_json
  end
  Date.today
  DB.run("BEGIN")
  nowf = DateTime.now.strftime("%Y/%m/%d %H:%M:%S")
  begin
    params['urls'].select{ |x| x.size > 0}.each do |data|
      url = data['url']
      img_tags_ins_list = []

      hs = Digest::SHA1.hexdigest(url)

      ext = /^[a-z]+/.match(URI.parse(url).path.split('.').last).to_a[0]

      next if File.exists?(img_url_path + hs + '.' + (ext||''))

      info = save_img(url, hs, ext)
      info[:url_hash] = hs
      info[:ext] = ext
      info[:created_at] = nowf
      info[:source_url] = url

      DB[:images].insert(info)
      puts "inserted image: #{url}"
      params['tags'].each do |tag|
        img_tags_ins_list << { url_hash: hs, tag: tag, created_at: nowf }
      end
      DB[:image_tags].multi_insert(img_tags_ins_list)
    end
    DB.run("COMMIT")
  rescue => e
    puts e.full_message
    # 失敗
    DB.run("ROLLBACK")
    rst[:status] = 400
    rst[:msg] = "database insert error."
    return rst.to_json
  end
  rst.to_json
end
