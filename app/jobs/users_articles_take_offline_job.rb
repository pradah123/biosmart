class UsersArticlesTakeOfflineJob < ApplicationJob
  queue_as :default

  def perform *user
    user.articles.each { |a| a.offline! }
  end
end
