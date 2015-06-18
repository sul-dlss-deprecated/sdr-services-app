require 'coveralls'
Coveralls.wear!

require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

require 'equivalent-xml'

require 'rack/test'
RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end
