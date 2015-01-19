# Note: capistrano reads this file AFTER config/deploy.rb

ENV['APP_ENV']  ||= 'development'
ENV['SDR_APP']  ||= fetch(:application)
ENV['SDR_HOST'] ||= 'localhost'
ENV['SDR_USER'] ||= ENV['USER']
ENV['SDR_URL']  ||= "http://#{ENV['SDR_HOST']}/sdr"

puts File.expand_path(__FILE__)
require_relative 'server_settings'

