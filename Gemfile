# frozen_string_literal: true

ruby '>= 3.2'

source 'https://rubygems.org'

gem 'nokogiri', '~> 1.18'
gem 'rake', '~> 13.2'
gem 'rubyzip', '~> 2.4'

group :test, :development do
  gem 'minitest', '~> 5.25'
  gem 'rubocop', '~> 1.75', require: false
  gem 'rubocop-minitest', '~> 0.38.0', require: false
  gem 'rubocop-rake', '~> 0.7.1', require: false
  gem 'simplecov', require: false
end

group :doc do
  gem 'rdoc', '~> 6.13'
  gem 'webrick', '~> 1.9'
  gem 'yard', '~> 0.9.37'
end
