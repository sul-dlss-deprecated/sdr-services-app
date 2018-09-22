#!/usr/bin/env ruby
# must run this from ~/sdr-services-app/current/
# usage is ruby /directory/of/script/createBag.rb /directory/with/druids/druid-list.txt /some/directory
# where /directory/of/script/createBag.rb is whereever you place this particular script
# and where /directory/with/druids/druid-list.txt is whereever your druid file list is
# NOTE: druids should be each on their own line in the list. Provide either the fully qualified druid (druid:pv564yb1711) or not (pv564yb1711)
# and where /some/directory is wherever you want the bags to land.  i usually place them in the tmp directory.

# first require some gems
require 'rubygems'
require 'bundler/setup'
require 'moab/stanford'
include Stanford

module SdrServices
  Config = Confstruct::Configuration.new do
      username  nil
      password nil
      storage_filesystems nil
      rsync_destination_host nil
      rsync_destination_home nil
  end
end

# determine environment variables based on the host name
environment = (
  case `hostname -s`.chomp
    when "sul-sdr-services", "sdr-services-app-stage"
      "production.rb"
    when "sdr-services-test"
      "sdr-services-test.rb"
    else
      'development'
  end
)
require File.join(ENV['HOME'],"sdr-services-app/current/config/environments/#{environment}")


#pull the file from the commandline argument and read each line into the druids array
druids = []
druidlist = File.open(ARGV[0])
druidlist.each_line {|line|
  druids.push line.chomp
}

#for each druid in the array
druids.each do |druid|
  begin
  # format the druid into the fully qualified druid if necessary
    druid = "druid:#{druid}" unless druid.start_with?('druid')
    # now find the storage object for each one of the objects using the druid
    storage_object = StorageServices.find_storage_object(druid)
    # get the current version of the object
    version_id = storage_object.current_version_id
    # specify where you want the bags place by pulling from the second argument on the commandline
    bag_dir = "#{ARGV[1]}/bags/#{druid}"
    # now using the version_id and the bag_dir, reconstruct the object
    storage_object.reconstruct_version(version_id, bag_dir)
  # rescue any errors you might get
  rescue ObjectNotFoundException => msg
    puts "#{druid}, #{msg}"
  end
end
