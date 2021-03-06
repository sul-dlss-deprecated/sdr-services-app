
Moab::Config.configure do
  storage_roots File.join(File.dirname(__FILE__), '..', '..', 'spec', 'fixtures')
  storage_trunk 'repository'
  deposit_trunk nil
  path_method :druid
end

SdrServices::Config.configure do
  username 'sdrUser'
  password 'sdrPass'
  admin_email ENV['USER']
  storage_filesystems ['/tmp']
  rsync_destination_host 'localhost'
  rsync_destination_path '/tmp/sdr_transfer'
end
