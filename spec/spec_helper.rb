ENV['RACK_ENV'] = "development"

require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

require 'equivalent-xml'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end
