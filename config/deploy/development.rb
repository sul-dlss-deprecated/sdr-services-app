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

server ENV['SDR_HOST'], user: ENV['SDR_USER'], roles: %w{app}
Capistrano::OneTimeKey.generate_one_time_key!

# Target path
USER_HOME = `ssh #{ENV['SDR_USER']}@#{ENV['SDR_HOST']} 'echo $HOME'`.chomp
set :deploy_to, "#{USER_HOME}/#{ENV['SDR_APP']}"

# NOTE: development might require https instead of git protocol
#set :repo_url, "https://github.com/sul-dlss/#{ENV['SDR_APP']}.git"
