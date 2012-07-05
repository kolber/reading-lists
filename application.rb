require 'sinatra/base'
require 'instapaper'
require 'data_mapper'
require 'sinatra/flash'
require 'uri'

require File.expand_path(File.join(*%w[ models init ]), File.dirname(__FILE__))

class Application < Sinatra::Base

  enable :sessions
  register Sinatra::Flash

  get "/new" do
    erb :new
  end

  post "/new" do
    Instapaper.configure do |config|
      config.consumer_key = KEY
      config.consumer_secret = SECRET
    end

    begin
      token = Instapaper.access_token(params[:username], params[:password])
    rescue
      flash.now[:auth_error] = ''
      return erb :new
    end

    Instapaper.configure do |config|
      config.consumer_key = KEY
      config.consumer_secret = SECRET
      config.oauth_token = token['oauth_token']
      config.oauth_token_secret = token['oauth_token_secret']
    end

    # HANDLE NON-SUBSCRIPTION USERS
    instapaper_user = Instapaper.verify_credentials
    if instapaper_user[0]['subscription_is_active'] == '0'
      flash.now[:no_subscription] = ''
      return erb :new
    end
    # PROTECT AGAINST DUPLICATE USERNAMES
    if User.count(:conditions => ['username = ?', params[:url]]) > 0
      flash.now[:duplicate_username] = ''
      return erb :new
    end

    user = User.new(:username => params[:url], :oauth_token => token['oauth_token'], :oauth_secret => token['oauth_token_secret'], :folder_name => params[:folder_name])
    if user.save
      redirect user.username+'/save-articles'
    else
      return erb :new
    end
  end

  get "/:username/save-articles" do
    user = User.first(:username => params[:username])
    Instapaper.configure do |config|
      config.consumer_key = KEY
      config.consumer_secret = SECRET
      config.oauth_token = user.oauth_token
      config.oauth_token_secret = user.oauth_secret
    end

    if user[:folder_id].nil?
      Instapaper.folders.each do |folder|
        user.folder_id = folder[:folder_id] if (folder[:title] && folder[:title].downcase == user.folder_name.downcase)
        user.save
        break
      end
    end

    existing_articles = user.articles.collect(&:instapaper_id).join(",")
    articles = Instapaper.bookmarks({folder_id: user[:folder_id], limit: ARTICLE_LIMIT, have: existing_articles }) || []
    articles.each do |a|
      article = Article.first(:url => a.url) || Article.create(:instapaper_id => a.bookmark_id, :url => a.url, :title => a.title, :time => a.time.to_s)
      user.articles << article
    end
    user.save
    redirect user.username
  end

  get "/:username" do
    @user = User.first(:username => params[:username])
    halt 404 if @user.nil?
    @articles = @user.articles.sort_by { |v| v[:time] }.reverse
    erb :index
  end

end