DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

class User
  include DataMapper::Resource
  property :id,           Serial
  property :username,     String, :required => true
  property :oauth_token,  String, :required => true
  property :oauth_secret, String, :required => true
  property :folder_name,  String, :required => true
  property :folder_id,    String
  property :completed_at, DateTime

  has n, :articles, :through => Resource
end

class Article
  include DataMapper::Resource
  property :id,            Serial
  property :url,           Text, :lazy => false
  property :time,          String
  property :title,         Text
  property :instapaper_id, Integer

  has n, :users, :through => Resource
end

DataMapper.auto_upgrade!

KEY = ENV['OAUTH_KEY']
SECRET = ENV['OAUTH_SECRET']
ARTICLE_LIMIT = 50