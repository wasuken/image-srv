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
                   tags: DB[:image_tags].where(url_hash: r[:url_hash]).to_a.map{ |u| u[:tag]}
                 }}.to_json
end

post '/api/v1/images' do
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
    params['urls'].select{ |x| x.size > 0}.each do |url|
      img_tags_ins_list = []

      next if File.exists?(url)

      hs = Digest::SHA1.hexdigest(url)

      ext = /^[a-z]+/.match(URI.parse(url).path.split('.').last).to_a[0]

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
    puts e.message
    # 失敗
    DB.run("ROLLBACK")
    rst[:status] = 400
    rst[:msg] = "database insert error."
    return rst.to_json
  end
  rst.to_json
end
