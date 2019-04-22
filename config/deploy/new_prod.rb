# NOTE: you should still use prod.rb for now.  this deployment config is WIP towards attempting to move sdr-services-app to a new VM.

ENV['APP_ENV'] ||= 'production'

server 'sdr-services-app-prod.stanford.edu', user: 'sdr2service', roles: %w{app}

Capistrano::OneTimeKey.generate_one_time_key!

set :deploy_to, '/opt/app/sdr2service/sdr-services-app'