require File.dirname(__FILE__) + '/config/boot.rb'

run Rack::URLMap.new({
  "/"    => Sdr::ServicesAPI,
})

log = File.new("log/sdr.log", "a+")

# comment this next line out if using Passenger 4.0
# see http://stackoverflow.com/questions/16776147/logger-fail-with-sinatra-1-4-2-ruby-2-0-0-p195-passenger-4-0-3-and-rack-1-5-2
# see https://github.com/phusion/passenger/wiki/Debugging-application-startup-problems
# Phusion Passenger uses the application's stdout for communication with the application.
#   This means that if, during any of those steps, stdout is closed, overwritten or redirected to a file,
#   then Phusion Passenger loses its means to communicate with the application.
#   After a while, Phusion Passenger concludes that the application fails to start up, and reports an error.
#$stdout.reopen(log)

# Hack for dev so log messages appear in terminal instead of log file
unless ENV['APP_ENV'] == 'development'
  $stderr.reopen(log)
  $stderr.sync = true
  $stdout.sync = true
end
