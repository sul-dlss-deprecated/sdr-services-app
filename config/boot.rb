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

case ENV["RACK_ENV"].to_sym
  # when  :development, :integration
  when  :integration
    env_file = "integration"
  when :test, :staging
    env_file = "staging"
  when :prod, :production
    env_file = "production"
  else
    env_file = "development"
end
env_path = File.expand_path(File.dirname(__FILE__) + "/environments/#{env_file}")
require env_path

puts "Loaded #{env_path}"
