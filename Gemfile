# vim: autoindent tabstop=2 shiftwidth=2 expandtab softtabstop=2 filetype=ruby
source 'https://rubygems.org'

# Bundle 'group' names correspond to ENV['APP_ENV'] names, see
# config/boot.rb for more information, esp. the use of
# Bundler.require(:default, ENV['APP_ENV'])

# Serializers
gem 'builder' # for xml
gem 'activesupport', '~> 5.2' # for xml
gem 'multi_json', '~> 1.0'
gem 'json-schema'

gem 'rack', '~> 1.5'
#gem 'rack-parser', :require => 'rack/parser'

gem 'sinatra', '~> 1.4'
gem 'sinatra-contrib'
gem 'sinatra-advanced-routes'
# https://github.com/rstacruz/sinatra-assetpack
#gem 'sinatra-assetpack', :require => 'sinatra/assetpack'

# http://code.macournoyer.com/thin/
gem 'thin'
gem 'foreman'
gem 'dotenv'

gem 'pry', '~> 0.10.1'
gem 'sys-filesystem'
gem 'slop'  # CLI parser

gem 'druid-tools'
gem 'moab-versioning', '~> 2.0'

# Database
group :staging, :production do
  gem 'ruby-oci8'
end
group :test, :development do
  gem 'mysql2'
end
gem 'sequel'

# Templating for /views/documentation
gem 'haml'
gem 'redcarpet'

group :test, :development do
  gem 'awesome_print'
  gem 'coveralls', require: false
  gem 'cucumber'
  gem 'database_cleaner'
  gem 'equivalent-xml'
  gem 'pry-doc'
  gem 'rack-test', :require => 'rack/test'
  gem 'randexp'
  gem 'rspec', '~> 3.0'
  gem 'simplecov', '~> 0.7'
  gem 'yard'
end

# Do not place the capistrano-related gems in the default or Rails.env bundle group
# Otherwise the config/application.rb's Bundle.require command will try to load them
# leading to failure because these gem's rake task files use capistrano DSL.
group :development do
  # Use Capistrano for deployment
  gem 'capistrano', '> 3.1'
  gem 'capistrano-rvm', '> 0.1'
  gem 'capistrano-bundler', '> 1.1'
  gem 'capistrano-passenger'
  gem 'dlss-capistrano', '> 3.0'
end

gem 'honeybadger'
