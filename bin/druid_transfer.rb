#!/usr/bin/env ruby

# Exit cleanly from an early interrupt
Signal.trap("INT") { exit 1 }

# Setup the bundled gems in our environment
require 'bundler/setup'
require 'moab_stanford'
require 'druid-tools'
require 'sys/filesystem'

# Configure the process for the current cron configuration.
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

# TODO: require the right environment configuration (dev/integration/production)


require 'optparse'
options = {}
opt_parser = OptionParser.new do |opts|
  # Set a banner, displayed at the top of the help screen.
  #opts.banner = "Usage: ncbo_ontology_index [options]"
  options[:druids] = false
  opts.on('-d', '--druids DRUID[,DRUID,...]', 'A list of DRUIDs to transfer (required).') do |druids|
    options[:druids] = druids.split(',')
  end
  options[:logfile] = "transfers.log"
  opts.on( '-l', '--logfile FILE', "Write log to FILE (default is 'transfers.log')" ) do |filename|
    options[:logfile] = filename
  end
  # Display the help screen, all programs are assumed to have this option.
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end
# Parse the command-line. The 'parse' method simply parses ARGV, while the 'parse!' method parses ARGV and removes
# any options found there, as well as any parameters for the options.
opt_parser.parse!
unless options[:druids]
  puts opt_parser.help
  exit(1)
end


# TODO: consider using ARGF to handle a DRUID file; see
# TODO: https://robm.me.uk/ruby/2013/12/03/argf-ruby.html

require 'pry'
binding.pry


# begin
#   logger = Logger.new(options[:logfile])
#   puts "Deletion details are logged to #{options[:logfile]}"
#   ont = LinkedData::Models::Ontology.find(options[:ontology]).first
#   if ont.nil?
#     msg = "Quitting, ontology not found: #{options[:ontology]}"
#     logger.error(msg)
#     puts msg
#     exit(1)
#   end
#   ont.delete
#   logger.info("Ontology deleted: #{options[:ontology]}")
# rescue Exception => e
#   msg = "Failed, exception: #{e.to_json}."
#   logger.error(msg)
#   puts msg
#   exit(1)
# end




notification_email = SdrServices::Config.admin_email

# assume the destination_host and destination_home are constant across all druids
destination_host = params[:destination_host]  # || default?
destination_home = params[:destination_home]  # || default?  should be an absolute path
return "Invalid parameters: " + JSON.dump(params) if destination_host.nil? || destination_home.nil?

# destination paths can take three different forms (prefixed with 'destination_home'):
# * druid-id (e.g.  jq937jp0017/)
# * druid-tree-short ( e.g. jq/937/jp/0017/)
# * druid-tree-long ( e.g. jq/937/jp/0017/jq937jp0017/)
destination_types = ['druid-id', 'druid-tree-short', 'druid-tree-long']
destination_type = destination_types.first # set default
if destination_types.include? params[:destination_type]
  destination_type = params[:destination_type]
end
#destination_type = params[:destination_type].to_sym || Moab::Config.path_method

# Collect an array of transfer commands, to executed in batch mode after parsing all the druids
transfer_commands = []
# process the druids to construct transfer commands
druids = params[:druids].split(',').uniq
druids.each do |druid_id|
  # validate druid
  unless DruidTools::Druid.valid?(druid_id)
    mail_error = "echo '' | mail -s 'sdr-transfer error: #{druid_id}: invalid druid syntax (eom)' #{notification_email}"
    system(mail_error)
    next
  end
  # retrieve the data to identify the repository path
  druid_moab = Stanford::StorageServices.find_storage_object(druid_id)
  if druid_moab.nil?
    mail_error = "echo '' | mail -s 'sdr-transfer error: #{druid_id}: cannot locate storage object (eom)' #{notification_email}"
    system(mail_error)
    next
  end
  source_path = druid_moab.object_pathname.to_s
  # construct destination path
  d = DruidTools::Druid.new(druid_id, destination_home)
  case destination_type
    when 'druid-tree-long'
      destination_path = d.path
    when 'druid-tree-short'
      destination_path = d.path.sub("/#{d.id}",'')
    when 'druid-id'
      destination_path = File.join(destination_home, d.id)
  end
  rsync_source = "#{source_path}"
  rsync_destination = "#{destination_host}:#{destination_path}"
  mkdir_cmd = "ssh #{destination_host} 'mkdir -p #{destination_path}'"
  mkdir_failure = "echo '' | mail -s 'sdr-transfer failure: cannot create remote path #{rsync_destination} (eom)' #{notification_email}"
  rsync_cmd = "rsync -a -e ssh '#{rsync_source}/' '#{rsync_destination}/'"
  rsync_success = "echo '' | mail -s 'sdr-transfer success: #{druid_id} to #{rsync_destination} (eom)' #{notification_email}"
  rsync_failure = "echo '' | mail -s 'sdr-transfer failure: #{druid_id} to #{rsync_destination} (eom)' #{notification_email}"
  transfer_commands.push("#{mkdir_cmd} || #{mkdir_failure}")
  transfer_commands.push("#{rsync_cmd} && #{rsync_success} || #{rsync_failure}")
end
`echo "#{transfer_commands.join('; ')}" | at now`
# alternative execution strategy:
# f=Tempfile.new('moab_rsync')
# transfer_commands.each {|cmd| f.puts(cmd + ";\n\n") }
# f.close
# system("at -f #{f.path} now")
puts "Scheduled transfers are running."

