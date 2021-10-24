require "json"
require "sequel"
require "mysql2"

require "./lib/dbio/imgsrv.rb"

APP_ENV = (ENV["ENV"] || "development").to_sym

CONFIG = JSON.parse(File.read("./config.#{APP_ENV}.json"))

DB = Sequel.mysql2(
  host: CONFIG["db"]["host"],
  user: CONFIG["db"]["user"],
  password: CONFIG["db"]["pass"],
  database: CONFIG["db"]["name"],
  encoding: "utf8",
)

IMGSRV = ImageServer.new(CONFIG, DB)

IMGSRV.restore_img()
