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

def save_img(url, save_name)
  img_path = CONFIG['app']['img_path']
  u = URI.parse(url)
  Net::HTTP.start(u.host) do |http|
    resp = http.get(u.path)
    open("#{img_path}#{save_name}", "wb") do |file|
      file.write(resp.body)
    end
  end
end

get '/' do
  erb :index
end

get '/post' do
  erb :post
end


get '/api/v1/images/top' do
  img_url_path = CONFIG['app']['img_url_path']
  $top.to_a.map{ |r| {
                   url: img_url_path + r[:url_hash],
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
    params['urls'].each do |url|
      img_tags_ins_list = []
      hs = Digest::SHA1.hexdigest(url)
      next if File.exists?(url)
      save_img(url, hs)
      DB[:images].insert({ url_hash:  hs, created_at: nowf})
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
