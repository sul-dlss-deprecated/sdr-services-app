ENV['APP_ENV'] ||= 'staging'

server 'sdr-services-app-stage.stanford.edu', user: 'sdr2service', roles: %w{app}

Capistrano::OneTimeKey.generate_one_time_key!

set :deploy_to, '/opt/app/sdr2service/sdr-services-app'

set :linked_files, %w(.env config/database.yml)
