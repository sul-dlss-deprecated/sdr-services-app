require File.expand_path(File.dirname(__FILE__) + "/../../config/boot")

def app
  @app ||= Sdr::ServicesAPI
end

require 'randexp'
class Randgen
  def self.lower(options = {})
    [*'a'..'z'].sample(options[:length]).join
  end
end


