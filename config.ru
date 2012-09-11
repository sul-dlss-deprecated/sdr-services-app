require File.dirname(__FILE__) + '/config/boot.rb'

run Rack::URLMap.new({
  "/"    => Sdr::ServicesApi,
})

log = File.new("log/sdr.log", "a+")
$stdout.reopen(log)
$stderr.reopen(log)
$stderr.sync = true
$stdout.sync = true