# frozen_string_literal: true

source "https://rubygems.org"

ruby "3.3.6"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}"  }

gem "activesupport"
gem "awesome_print"
gem "byebug"
gem "httparty"
gem "influxdb"
gem "parallel"
gem "rspec"


group :development do
  gem "rubocop", require: false
  gem "rubocop-github"
  gem "rubocop-performance", require: false # It's a hard dependency from rubocop-github gem.
  gem "rubocop-rails" , require: false # Similarly another hard dependency from rubocop-github gem.
  gem "rubocop-rspec", require: false
end

group :test do
  gem "simplecov", require: false
end
