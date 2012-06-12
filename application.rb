require 'sinatra/base'
require 'instapaper'

class Application < Sinatra::Base
  enable :sessions

  KEY = ENV['KEY']
  SECRET = ENV['SECRET']
  OAUTH_TOKEN = ENV['OAUTH_TOKEN']
  OAUTH_TOKEN_SECRET = ENV['OAUTH_TOKEN_SECRET']
  FOLDER_NAME = 'Canon'
  ARTICLE_LIMIT = 50

  get "/" do

    Instapaper.configure do |config|
      config.consumer_key = KEY
      config.consumer_secret = SECRET
      config.oauth_token = OAUTH_TOKEN
      config.oauth_token_secret = OAUTH_TOKEN_SECRET
    end

    target_id = false
    Instapaper.folders.each do |folder|
      target_id = folder[:folder_id] if (folder[:title].downcase == FOLDER_NAME.downcase)
    end

    @articles = Instapaper.bookmarks({folder_id: target_id, limit: ARTICLE_LIMIT })
    erb :index

  end

end