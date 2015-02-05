
# See also ~/sdr-services-app/shared/.env

SDR_HOME = File.join(File.dirname(__FILE__), '..', '..', 'spec')
SDR_REPO = File.join( SDR_HOME, 'fixtures')

Moab::Config.configure do
  #storage_roots Dir.glob( File.join(SDR_REPO, 'store*')).sort
  storage_roots SDR_REPO
  storage_trunk 'repository'
  deposit_trunk nil
  path_method :druid
end

SdrServices::Config.configure do
  username 'sdrUser'
  password 'sdrPass'
  admin_email ENV['USER']
  storage_filesystems ['/']
  rsync_destination_host 'localhost'
  rsync_destination_path '/tmp/sdr_transfer'
end

