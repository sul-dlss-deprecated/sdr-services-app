#!/usr/bin/env ruby
# must run this from ~/sdr-services-app/current/
# usage is ruby /directory/of/script/objectFileInfo.rb /directory/with/druids/druid-list.txt
# where /directory/of/script/objectFileInfo.rb is whereever you place this particular script
# and where /directory/with/druids/druid-list.txt is whereever your druid file list is
# NOTE: druids should be each on their own line in the list. Provide either the fully qualified druid (druid:pv564yb1711) or not (pv564yb1711)
# NOTE: I ususally output this script like so: ruby /tmp/rmetz/objectFileInfo.rb /tmp/rmetz/sdrget-2078.txt > /tmp/rmetz/sdrget-2078.csv
#and then download it for use in excel

# ******************
# 2019-09-17:  THIS SCRIPT IS DEPRECATED - it has been replaced by the "Checksum Report" bulk action in Argo
# ******************

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

environment = (
  case `hostname -s`.chomp
    when "sul-sdr-services", "sdr-services-app-stage", "sdr-services-app-prod"
      "production.rb"
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
    #format the druid so that its fully qualified (unless it already is)
    druid = "druid:#{druid}" unless druid.start_with?('druid')
    #pull information about the storage object
    content_group = StorageServices.retrieve_file_group('content',druid)
    #then parse that information that you just retrieved
    content_group.path_hash.each do |file,signature|
      #into a .csv file that contains the druid, file, md5 checksum, sha1 checksum, sha256 checksum, and the size of the object
      puts "#{druid}, #{file.to_s}, #{signature.md5}, #{signature.sha1}, #{signature.sha256}, #{signature.size}"
    end
  #if the object doesn't exist for some reason, rescue the error message
  rescue ObjectNotFoundException => msg
    puts "#{druid}, #{msg}"
  end
end
