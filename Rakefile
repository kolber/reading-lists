task :environment do
  require File.expand_path(File.join(*%w[ config environment ]), File.dirname(__FILE__))
  require_relative 'models/init'
end

task :cron => :environment do

  User.all.each do |user|
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
      p a.url
      user.articles << article
    end
    user.save
  end

end