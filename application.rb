require 'sinatra/base'
require 'instapaper'
require 'data_mapper'

class Application < Sinatra::Base
  enable :sessions

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
      return "Instapaper Username or Password is incorrect."
    end

    # HANDLE NON-SUBSCRIPTION USERS
    # PROTECT AGAINST DUPLICATE USERNAMES

    user = User.new(:username => params[:url], :oauth_token => token['oauth_token'], :oauth_secret => token['oauth_token_secret'], :folder_name => params[:folder_name])
    if user.save
      redirect user.username+'/save-articles'
    else
      redirect '/new'
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
    @articles = @user.articles
    erb :index
  end

end

require_relative 'models/init'