Moab::Config.configure do
  storage_roots File.join(File.dirname(__FILE__), '..', '..', 'spec', 'fixtures')
  storage_trunk 'repository'
  deposit_trunk nil
  path_method :druid
end

SdrServices::Config.configure do
  username 'devUser'
  password 'devPass'
  admin_email ENV['USER']
  storage_filesystems ['/']
  rsync_destination_host ''
  rsync_destination_home '/tmp'
end
