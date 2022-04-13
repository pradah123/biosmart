source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.0.2'

gem 'rails', '~> 6.1.4'
gem 'sqlite3', '~> 1.4'
gem 'puma', '~> 5.0'
gem 'sass-rails', '>= 6'
gem 'webpacker', '~> 5.0'
gem 'turbolinks', '~> 5'
gem 'jbuilder', '~> 2.7'
gem 'bcrypt', '~> 3.1.7'
gem 'bootsnap', '>= 1.4.4', require: false
gem 'image_processing', '~> 1.2'

gem 'json', '2.6.0'
gem 'jsonapi-serializer'
gem 'rails_admin'
gem 'rails_admin-i18n'
gem 'rails_admin_toggleable'
gem 'rails_admin_globalize_field'
gem 'jwt'
gem 'pg'

gem 'delayed_job'
gem 'delayed_job_active_record'
gem 'delayed_job_web'
gem 'daemons'

gem 'geokit'
gem 'rack-attack'
gem 'rack-cors'
gem 'httparty'
gem 'dry-transformer'
gem 'dry-struct'
gem 'dry-initializer'
gem 'dry-types'
gem 'dotenv-rails', groups: [:development, :test]
gem 'timezone_finder'

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem 'web-console', '>= 4.1.0'
  #gem 'rack-mini-profiler', '~> 2.0'
  gem 'listen', '~> 3.3'
  gem 'spring'
end

group :test do
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end
