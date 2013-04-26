# RACK_ENV is set in /etc/httpd/conf.d/zzz-sdr-services.conf
# which in turn derives its value from z-RailsEnv.conf
ENV["RACK_ENV"] ||= "development"

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default, ENV["RACK_ENV"].to_sym)

#require 'lyber_core'

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
require 'sdr/services_api'
#Dir["../lib/**/*.rb"].each { |f| require f }

#LyberCore::Log.set_logfile(File.join(File.dirname(__FILE__), "..", "log", "sdr_services.log"))
#if(ENV["RACK_ENV"] == "production")
#  LyberCore::Log.set_level(1)
#else
#  LyberCore::Log.set_level(0)
#end

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
  when :development
    "development.rb"
  when :test
    "sdr-services-test.rb"
  when :prod, :production
    "sdr-services.rb"
  else
    "development.rb"
  end
env_path = File.expand_path(File.dirname(__FILE__) + "/environments/#{env_file}")
require env_path

