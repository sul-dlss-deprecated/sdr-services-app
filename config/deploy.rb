# config valid only for Capistrano 3.x
#lock '3.2.1'

set :application, 'sdr-services-app'

# Default value for :scm is :git
# set :scm, :git

# NOTE: production is not working with https (old openssl?)
# set :repo_url, 'https://github.com/sul-dlss/sdr-services-app.git'
set :repo_url, 'git@github.com:sul-dlss/sdr-services-app.git'

# Default branch is :master
ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :info

# Default value for :pty is false
# set :pty, true

# https://github.com/capistrano/bundler#usage
# Options, with defaults:
#set :bundle_roles, :all                                         # this is default
#set :bundle_servers, -> { release_roles(fetch(:bundle_roles)) } # this is default
#set :bundle_binstubs, -> { shared_path.join('bin') }            # this is default
#set :bundle_gemfile, -> { release_path.join('MyGemfile') }      # default: nil
#set :bundle_path, -> { shared_path.join('bundle') }             # this is default
#set :bundle_without, %w{development test}.join(' ')             # this is default
#set :bundle_flags, '--deployment --quiet'                       # this is default
#set :bundle_env_variables, {}                                   # this is default
set :bundle_binstubs, -> { shared_path.join('.binstubs') }
set :bundle_without, %w{development local test}.join(' ')
set :bundle_flags, '--deployment'

# Default value for linked_dirs is []
# The config/environments must contain an ENV['APP_ENV'] config file.
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_dirs, %w(.binstubs log config/environments)

# Default value for :linked_files is []
# The .env and config/database.yml are private files that must be
# manually placed on the deployment system into the shared path.
# The shared/.env file contains deployment-specific ENV values,
# and the config/deploy/{APP_ENV}.rb file contains a :default_env.
set :linked_files, %w(.env config/database.yml)

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
  # Capistrano 3 no longer runs deploy:restart by default.
  after :publishing, :restart
end

# capistrano next reads config/deploy/#{target}.rb, e.g.:
# config/deploy/development.rb

