ENV['APP_ENV'] ||= 'production'

set :default_env, 'APP_ENV' => ENV['APP_ENV']

server 'sul-sdr-services.stanford.edu', user: 'sdr2service', roles: %w{app}

Capistrano::OneTimeKey.generate_one_time_key!
