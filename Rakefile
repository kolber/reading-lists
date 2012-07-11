task :environment do
  require File.expand_path(File.join(*%w[ config environment ]), File.dirname(__FILE__))
  require_relative 'models/init'
end

task :cron => :environment do

  # Loop through each user looking for new or removed articles and update accordingly
  User.all.each do |user|

    p "--------------"
    p "#{user.username} - #{user.email}"

    # Authorise
    Instapaper.configure do |config|
      config.consumer_key = KEY
      config.consumer_secret = SECRET
      config.oauth_token = user.oauth_token
      config.oauth_token_secret = user.oauth_secret
    end

    # If the user doesn't have a folder_id yet, try find one
    # (this would occur if the signed up with a folder which didn't yet exist)
    if user[:folder_id].nil?
      Instapaper.folders.each do |folder|
        user.folder_id = folder[:folder_id] if (folder[:title] && folder[:title].downcase == user.folder_name.downcase)
        user.save
        break
      end
    end

    existing_articles = user.articles.group_by(&:instapaper_id)
    # Look for new articles to add
    articles = Instapaper.bookmarks({folder_id: user[:folder_id], limit: ARTICLE_LIMIT }) || []
    articles.each do |a|
      unless existing_articles.has_key?(a.bookmark_id)
        article = Article.first(:url => a.url) || Article.create(:instapaper_id => a.bookmark_id, :url => a.url, :title => a.title, :time => a.time.to_s)
        p "Added: #{a.url}"
        user.articles << article
      end
    end
    # Look for articles no longer in the folder to remove
    article_ids = articles.collect(&:bookmark_id)
    user.articles.each do |a|
      unless article_ids.include?(a.instapaper_id)
        p "Remove: #{a.url}"
        user.articles.delete(a)
      end
    end

    user.save

  end

end