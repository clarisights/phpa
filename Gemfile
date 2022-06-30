# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}"  }

gem "activesupport"
gem "awesome_print"
gem "byebug"
gem "httparty"
gem "influxdb"
gem "parallel"
gem "rspec"


group :development do
  gem "rubocop", "~> 1.31.1", require: false
  gem "rubocop-github", "~> 0.18.0"
  gem "rubocop-performance", "~> 1.14.2", require: false # It's a hard dependency from rubocop-github gem.
  gem "rubocop-rails", "~> 2.15.1" , require: false # Similarly another hard dependency from rubocop-github gem.
  gem "rubocop-rspec", "~> 2.11.1" , require: false
end

group :test do
  gem "simplecov", "~> 0.21.2", require: false
end
