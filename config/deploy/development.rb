# Note: capistrano reads this file AFTER config/deploy.rb

ENV['SDR_APP']  ||= fetch(:application)
ENV['SDR_HOST'] ||= 'hostname'
ENV['SDR_USER'] ||= 'username'

puts File.expand_path(__FILE__)
puts "ENV['SDR_APP']  = #{ENV['SDR_APP']}"
puts "ENV['SDR_HOST'] = #{ENV['SDR_HOST']}"
puts "ENV['SDR_USER'] = #{ENV['SDR_USER']}"
puts

set :default_env, {
    'SDR_APP'  => ENV['SDR_APP'],
    'SDR_USER' => ENV['SDR_USER'],
    'SDR_HOST' => ENV['SDR_HOST'],
}

require_relative 'server_settings'

