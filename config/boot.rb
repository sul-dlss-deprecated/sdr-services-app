
# This app is best started by the two scripts in
# bin/test.sh sets APP_ENV & RACK_ENV to 'test'
# bin/boot.sh allows foreman to use .env

# Uses local .env file, it doesn't override existing settings
require 'dotenv'
Dotenv.load

# APP_ENV is set by foreman (using .env) or defaults to 'test' here.
# This APP_ENV determines:
# 1. loading of config/environment/{APP_ENV}.rb
# 2. loading an APP_ENV section from config/database.yml
ENV['APP_ENV'] ||= 'development'
puts 'APP_ENV: ' + ENV['APP_ENV']

# RACK_ENV is set by foreman (using .env) or in /etc/httpd/conf.d/{hostname}.conf
# which in turn derives its value from z-RailsEnv.conf
# This blog post suggests that RACK_ENV can only be “development”, “deployment”, and “none”.
# http://www.hezmatt.org/~mpalmer/blog/2013/10/13/rack_env-its-not-for-you.html
ENV['RACK_ENV'] ||= 'development'
puts 'RACK_ENV: ' + ENV['RACK_ENV']

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, ENV['APP_ENV'])

# Rack middleware
# use Rack::Parser, :parsers => {
#     'application/json' => proc { |data| MultiJson.load data },
#     'application/xml'  => proc { |data| XML.parse data },
# }

# Application
$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
require 'sdr/services_api'

module SdrServices
  Config = Confstruct::Configuration.new do
      username  nil
      password nil
      storage_filesystems nil
      rsync_destination_host nil
      rsync_destination_home nil
  end
end

case ENV['APP_ENV'].to_sym
  when :test
    # rspec config
    raise "Invalid RACK_ENV=#{ENV['RACK_ENV']}, should be 'test'" unless ENV['RACK_ENV'] == 'test'
    env_file = 'test'
  when :integration
    raise "Invalid RACK_ENV=#{ENV['RACK_ENV']}, should be 'development'" unless ENV['RACK_ENV'] == 'development'
    env_file = 'integration'
  when :stage, :staging
    raise "Invalid RACK_ENV=#{ENV['RACK_ENV']}, should be 'production'" unless ENV['RACK_ENV'] == 'production'
    env_file = 'staging'
  when :prod, :production
    raise "Invalid RACK_ENV=#{ENV['RACK_ENV']}, should be 'production'" unless ENV['RACK_ENV'] == 'production'
    env_file = 'production'
  else
    # defaults
    raise "Invalid RACK_ENV=#{ENV['RACK_ENV']}, should be 'development'" unless ENV['RACK_ENV'] == 'development'
    env_file = 'development'
end
env_path = File.expand_path(File.dirname(__FILE__) + "/environments/#{env_file}")
require env_path
puts "Loaded #{env_path}"


# If you are using a forking webserver such as unicorn or passenger, with a feature that
# loads your Sequel code before forking connections (code preloading), then you must
# disconnect your database connections before forking. If you don't do this, you can
# end up with child processes sharing database connections and all sorts of weird
# behavior. Sequel will automatically reconnect on an as needed basis in the child
# processes, so you only need to do the following in the parent process:
ArchiveCatalogSQL::DB.disconnect
