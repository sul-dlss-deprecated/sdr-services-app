# RACK_ENV is set in /etc/httpd/conf.d/{hostname}.conf
# which in turn derives its value from z-RailsEnv.conf
ENV["RACK_ENV"] ||= "local"

require 'rubygems'
require 'bundler/setup'
require 'sinatra'

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

env_file = case ENV["RACK_ENV"].to_sym
  when  :development, :integration
    "integration"
  when :test, :staging
    "staging"
  when :prod, :production
    "production"
  else
    "development"
  end
env_path = File.expand_path(File.dirname(__FILE__) + "/environments/#{env_file}")
require env_path

