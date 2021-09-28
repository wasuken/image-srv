require 'sequel'
require 'json'

CONFIG = JSON.parse(File.read('./config.json'))

DB = Sequel.mysql2(
  host: CONFIG['db']['host'],
  user: CONFIG['db']['user'],
  password: CONFIG['db']['pass'],
  database: CONFIG['db']['name'],
  encoding: 'utf8'
)

DB.create_table :images do
  String :url_hash
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
