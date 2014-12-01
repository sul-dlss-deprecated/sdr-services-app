# Note: this file is required in config/deploy/<environment>.rb

server ENV['SDR_HOST'], user: ENV['SDR_USER'], roles: %w{app}
Capistrano::OneTimeKey.generate_one_time_key!
ssh_opts = fetch(:ssh_options)
ssh_opts[:forward_agent] = true
ssh_opts[:verbose] = false
# The :ssh_options are set by
# capistrano-one_time_key/blob/master/lib/capistrano/tasks/one_time_key.rake

# Target path
USER_HOME = `ssh #{ENV['SDR_USER']}@#{ENV['SDR_HOST']} 'echo $HOME'`.chomp
set :deploy_to, "#{USER_HOME}/#{ENV['SDR_APP']}"

