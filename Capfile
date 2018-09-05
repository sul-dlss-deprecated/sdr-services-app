# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# https://github.com/capistrano/bundler#usage
require 'capistrano/bundler'

# https://github.com/capistrano/passenger/
# https://github.com/capistrano/passenger/#note-for-rvm-users
require 'capistrano-passenger'

#   https://github.com/capistrano/rvm
require 'capistrano/rvm'

#   https://github.com/capistrano/rbenv
# require 'capistrano/rbenv'

#   https://github.com/capistrano/chruby
# require 'capistrano/chruby'

#   https://github.com/capistrano/rails
# require 'capistrano/rails/assets'
# require 'capistrano/rails/migrations'

require 'dlss/capistrano'
require 'capistrano/honeybadger'

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
