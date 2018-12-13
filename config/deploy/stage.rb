server 'sdr-services-app-stage.stanford.edu', user: 'sdr2service', roles: %w{app}

Capistrano::OneTimeKey.generate_one_time_key!

set :honeybadger_env, 'stage'

set :deploy_to, '/opt/app/sdr2service/sdr-services-app'
