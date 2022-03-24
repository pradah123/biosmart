class UsersArticleTextUpdateJob < ApplicationJob
  queue_as :default

  def perform *user
    user.articles.each { |a| a.save! }
  end
end
