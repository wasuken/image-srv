# coding: utf-8
require 'sequel'
require 'json'

APP_ENV = (ENV['ENV'] || 'development').to_sym
CONFIG = JSON.parse(File.read("./config.#{APP_ENV}.json"))

DB = Sequel.mysql2(
  host: CONFIG['db']['host'],
  user: CONFIG['db']['user'],
  password: CONFIG['db']['pass'],
  database: CONFIG['db']['name'],
  encoding: 'utf8'
)

DB.create_table :images do
  String :url_hash
  String :ext
  Integer :bytesize
  Integer :width
  Integer :height
  String :source_url
  DateTime :created_at
  primary_key [:url_hash]
end

DB.create_table :image_tags do
  String :url_hash
  String :tag
  DateTime :created_at
  primary_key [:url_hash, :tag]
  index :tag
end
