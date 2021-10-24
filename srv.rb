# coding: utf-8
require "sinatra"
require "sinatra/reloader"
require "json"
require "sequel"
require "mysql2"
require "open-uri"
require "net/http"
require "nokogiri"
require "base64"
require "cgi"
require "benchmark"

require "./lib/dbio/imgsrv.rb"

APP_ENV = (ENV["ENV"] || "development").to_sym

CONFIG = JSON.parse(File.read("./config.#{APP_ENV}.json"))

configure do
  set :bind, "0.0.0.0"
  set :port, 3000
  set :environment, :production
  register Sinatra::Reloader
  also_reload "./*.rb"
end

DB = Sequel.mysql2(
  host: CONFIG["db"]["host"],
  user: CONFIG["db"]["user"],
  password: CONFIG["db"]["pass"],
  database: CONFIG["db"]["name"],
  encoding: "utf8",
)

IMGSRV = ImageServer.new(CONFIG, DB)

get "/" do
  erb :index
end

get "/post" do
  erb :post
end

get "/api/v1/img/in/page" do
  url = params["url"]
  uri = URI.encode_www_form_component(url, enc = nil)
  uri = uri.gsub(/%3A/, ":").gsub(/%2F/, "/")
  doc = Nokogiri::HTML(URI.open(uri))
  imgs = []

  u = URI.parse(uri)
  hostsc = "#{u.scheme}://#{u.host}"
  doc.css("img").each do |img|
    src = img.attr("src")
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

  if ["desc", "asc"].include?(order)
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

  if ["and", "or"].include?(tp)
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

get "/api/v1/images/search" do
  pms = JSON.parse(params.to_json)
  params = parse_search_params(pms)
  rst = {}
  begin
    rst = IMGSRV.search(params)
    rst[:status] = 200
  rescue => e
    puts e.full_message
    rst[:status] = 900
    rst[:msg] = e.full_message
  end
  rst.to_json
end

post "/api/v1/images" do
  content_type :json
  rst = {
    status: 200,
    msg: "success",
  }
  params = JSON.parse request.body.read

  unless params["urls"].size > 0
    rst[:status] = 400
    rst[:msg] = "not data"
    return rst.to_json
  end
  Date.today
  DB.run("BEGIN")
  begin
    IMGSRV.post(params)
  rescue => e
    puts e.full_message
    # 失敗
    DB.run("ROLLBACK")
    rst[:status] = 400
    rst[:msg] = "database insert error."
  end
  DB.run("COMMIT")
  rst.to_json
end
