ENV['APP_ENV'] ||= 'production'

set :default_env, 'APP_ENV' => ENV['APP_ENV']

server 'sdr-services-app-prod.stanford.edu', user: 'sdr2service', roles: %w{app}

Capistrano::OneTimeKey.generate_one_time_key!

set :deploy_to, '/opt/app/sdr2service/sdr-services-app'

set :honeybadger_env, 'prod'
