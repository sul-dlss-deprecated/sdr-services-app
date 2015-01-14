# Note: this file is required in config/deploy/<environment>.rb

puts "ENV['APP_ENV']  = #{ENV['APP_ENV']}"
puts "ENV['SDR_APP']  = #{ENV['SDR_APP']}"
puts "ENV['SDR_USER'] = #{ENV['SDR_USER']}"
puts "ENV['SDR_HOST'] = #{ENV['SDR_HOST']}"
puts "ENV['SDR_URL']  = #{ENV['SDR_URL']}"
puts

set :default_env, {
    'APP_ENV'  => ENV['APP_ENV'],
    'SDR_APP'  => ENV['SDR_APP'],
    'SDR_USER' => ENV['SDR_USER'],
    'SDR_HOST' => ENV['SDR_HOST'],
    'SDR_URL'  => ENV['SDR_URL'],
}

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

def upload_configs(remote_path, config_files = [])
  config_files.each do |local_path|
    if File.exist? local_path
      remote_file = File.join(remote_path, File.basename(local_path))
      info "Uploading local config file: #{local_path}"
      upload! StringIO.new(IO.read(local_path)), remote_file
    else
      fail "Missing config file: #{local_path}"
    end
  end
end

namespace :deploy do
  desc 'Upload environment configuration files to the remote server'
  task :upload_configs do
    on release_roles :all do
      within shared_path do
        # Upload the required environment config files
        local_config_deploy_path = File.absolute_path(File.dirname(__FILE__))
        local_config_path = local_config_deploy_path.sub('config/deploy', 'config')
        local_config_file = File.join(local_config_path, 'environments', "#{ENV['APP_ENV']}.rb")
        remote_config_path = File.join(shared_path, 'config')
        remote_env_path = File.join(remote_config_path, 'environments')
        upload_configs(remote_env_path, [ local_config_file ])
        # scp config/database.yml  sdrUser@sdrServices:~/sdr-services-app/shared/config/database.yml
        local_config_db_file = File.join(local_config_path, 'database.yml')
        upload_configs(remote_config_path, [ local_config_db_file ])
      end
    end
  end
end
after 'deploy:check:linked_dirs', 'deploy:upload_configs'

