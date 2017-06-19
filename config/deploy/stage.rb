require_relative 'server_settings'

server 'sdr-services-test.stanford.edu', user: 'sdr2service', roles: %w{app}
set :deploy_to, "/var/sdr2service/#{ENV['SDR_APP']}"

Capistrano::OneTimeKey.generate_one_time_key!
