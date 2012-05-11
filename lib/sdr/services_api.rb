require 'moab_stanford'

module Sdr
  class ServicesApi < Sinatra::Base

    # TODO add exception logging
    get '/sdr/objects' do 
      'ok'
    end
        
    post '/sdr/objects/:druid/cm-inv-diff' do
      request.body.rewind
      cmd_xml = request.body.read

      diff = Stanford::StorageServices.compare_cm_to_version_inventory(cmd_xml, params[:druid], params[:version].to_i).to_xml
      [200, {'content-type' => 'application/xml'}, diff]
    end
    
    # I did this to be able to wrap my app in Rack::Auth::Digest for example
    ## Example:
    ## def self.new(*)
    ##  app = Rack::Auth::Digest::MD5.new(super) do |username|
    ##    {'foo' => 'bar'}[username]
    ##  end
    ##  app.realm = 'Foobar::Foo'
    ##  app.opaque = 'secretstuff'
    ##  app
    ## end   
    
    def self.new(*)
      super
    end
    
  end
end
