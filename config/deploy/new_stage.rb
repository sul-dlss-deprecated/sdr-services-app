# NOTE: you should still use stage.rb for now.  this deployment config is WIP towards attempting to move sdr-services-app to a new VM.

ENV['APP_ENV'] ||= 'staging'

server 'sdr-services-app-stage.stanford.edu', user: 'sdr2service', roles: %w{app}

Capistrano::OneTimeKey.generate_one_time_key!

set :deploy_to, '/opt/app/sdr2service/sdr-services-app'

set :linked_files, %w(config/database.yml)
