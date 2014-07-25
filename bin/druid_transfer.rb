#!/usr/bin/env ruby

# Exit cleanly from an early interrupt
Signal.trap("INT") { exit 1 }

# Setup the bundled gems in our environment
require 'bundler/setup'
require 'moab_stanford'
require 'druid-tools'
require 'sys/filesystem'
require 'logger'
require 'slop'  # CLI parser
require 'pry'

# Bootstrap this environment (loads ../config/environment/?)
require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

logfile = File.expand_path(File.dirname(__FILE__) + '/../log/druid_transfers.log')

###
# CLI option parsing

tabs="\n\t\t\t\t"
destination_type_help = "" +
    "'druid-id'            (jq937jp0017) [default]#{tabs}" +
    "or 'druid-tree-short' (jq/937/jp/0017)#{tabs}" +
    "or 'druid-tree-long'  (jq/937/jp/0017/jq937jp0017)#{tabs}"

destination_host_help = "DESTINATION_HOST - {user}@{host}#{tabs}" +
    "where ssh automated authorization is enabled for {user}@{host}#{tabs}"
destination_path_help = "DESTINATION_PATH - /absolute/path/to/remote/repository#{tabs}" +
    "where {user}@{host} has write permissions to create this path and write files#{tabs}"

# Work around conflict in common use of '-h' for help in ARGV,
# because '-h' is used for '--destination_host' in this script.
ARGV[0] = '--help' if ARGV.include?('-h') && ARGV.length == 1

opts = Slop.parse! do
  banner "Usage: #{__FILE__} [OPTIONS] [FILES]"
  on 'd', :druids=, 'DRUID[,DRUID,...] - a list of DRUIDs (or use STDIN or FILES).', as: Array, default: []
  on 'h', :destination_host=, destination_host_help, default: SdrServices::Config.rsync_destination_host
  on 'p', :destination_path=, destination_path_help, default: SdrServices::Config.rsync_destination_path
  on 't', :destination_type=, destination_type_help, default: 'druid-id'  # TODO use: Moab::Config.path_method ?
  on 'l', :logfile=, "FILE  - log to FILE (default='log/druid_transfers.log')#{tabs}", default: logfile
  on 'help'
end
if opts[:help]
  puts opts
  exit
end
if opts[:druids].empty?
  puts 'Reading DRUIDs from STDIN' if ARGV.length < 1
  ARGF.each do |line|
    puts "Reading DRUIDs from #{ARGF.filename}:" if ARGF.file.lineno == 1
    opts[:druids].push(line.chomp)
  end
end
# puts opts.to_hash
if opts[:druids].empty?
  puts opts
  exit(1)
end



###
# Main

@logger = Logger.new(opts[:logfile])
puts "Transfer details are logged to #{opts[:logfile]}"

def mail_cmd(msg)
  "echo '' | mail -s '#{msg} (eom)' #{SdrServices::Config.admin_email}"
end

def transfer_error(error_msg)
  @logger.error(error_msg)
  system(mail_cmd error_msg)
end


begin
  # assume the destination_host and destination_path are constant across all druids
  destination_host = opts[:destination_host]
  destination_path = opts[:destination_path]

  # destination paths can take three different forms (prefixed with 'destination_path'):
  # * druid-id          - e.g. jq937jp0017
  # * druid-tree-short  - e.g. jq/937/jp/0017
  # * druid-tree-long   - e.g. jq/937/jp/0017/jq937jp0017
  destination_types = %w(druid-id druid-tree-short druid-tree-long)
  if destination_types.include? opts[:destination_type]
    destination_type = opts[:destination_type]
  else
    destination_type = destination_types.first # set default
    #destination_type = Moab::Config.path_method
  end

  # Collect an array of transfer commands, to executed in batch mode after parsing all the druids
  transfer_commands = []
  # process the druids to construct transfer commands
  druids = opts[:druids].uniq
  druids.each do |druid_id|
    # validate druid
    unless DruidTools::Druid.valid?(druid_id)
      transfer_error "sdr-transfer error: #{druid_id}: invalid druid syntax"
      next
    end
    # retrieve the data to identify the repository path
    druid_moab = Stanford::StorageServices.find_storage_object(druid_id)
    if druid_moab.nil?
      transfer_error  "sdr-transfer error: #{druid_id}: cannot locate storage object"
      next
    end
    source_path = druid_moab.object_pathname.to_s
    # construct destination path
    d = DruidTools::Druid.new(druid_id, destination_path)
    case destination_type
      when 'druid-tree-long'
        destination_path = d.path
      when 'druid-tree-short'
        destination_path = d.path.sub("/#{d.id}",'')
      when 'druid-id'
        destination_path = File.join(destination_path, d.id)
    end
    rsync_source = "#{source_path}"
    rsync_destination = "#{destination_host}:#{destination_path}"

    mkdir_cmd = "ssh #{destination_host} 'mkdir -p #{destination_path}'"
    mkdir_failure = mail_cmd "sdr-transfer failure: cannot create remote path #{rsync_destination}"
    transfer_commands.push("#{mkdir_cmd} || #{mkdir_failure}")

    rsync_cmd = "rsync -a -e ssh '#{rsync_source}/' '#{rsync_destination}/'"
    rsync_success = mail_cmd "sdr-transfer success: #{druid_id} to #{rsync_destination}"
    rsync_failure = mail_cmd "sdr-transfer failure: #{druid_id} to #{rsync_destination}"
    transfer_commands.push("#{rsync_cmd} && #{rsync_success} || #{rsync_failure}")
    @logger.info(rsync_cmd)
  end

  `echo "#{transfer_commands.join('; ')}" | at now`

  # alternative execution strategy:
  # f=Tempfile.new('moab_rsync')
  # transfer_commands.each {|cmd| f.puts(cmd + ";\n\n") }
  # f.close
  # system("at -f #{f.path} now")  # system 'swallows' exceptions.

rescue Exception => e
  transfer_error "sdr-transfer failed with exception: #{e.to_json}."
  exit(1)
else
  puts "Scheduled transfers are running."
end



