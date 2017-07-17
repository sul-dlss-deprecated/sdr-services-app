ENV['APP_ENV'] ||= 'staging'

set :default_env, 'APP_ENV' => ENV['APP_ENV']

server 'sdr-services-test.stanford.edu', user: 'sdr2service', roles: %w{app}

Capistrano::OneTimeKey.generate_one_time_key!

set :honeybadger_env, 'stage'
