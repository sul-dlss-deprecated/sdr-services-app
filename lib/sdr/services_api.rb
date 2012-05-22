require 'moab_stanford'

module Sdr
  class ServicesApi < Sinatra::Base

    # TODO add exception logging
    get '/sdr/objects' do 
      'ok'
    end

    get '/sdr/objects/:druid/current_version' do
      current_version = Stanford::StorageServices.current_version(params[:druid])
      [200, {'content-type' => 'application/xml'}, "<currentVersion>#{current_version.to_s}</currentVersion>"]
    end

    get '/sdr/objects/:druid/version_metadata' do
      version_metadata = Stanford::StorageServices.version_metadata(params[:druid])
      [200, {'content-type' => 'application/xml'}, version_metadata.read]
    end

    get '/sdr/objects/:druid/version_differences' do
      version_differences = Stanford::StorageServices.version_differences(params[:druid], params[:base].to_i, params[:compare].to_i)
      [200, {'content-type' => 'application/xml'}, version_differences.to_xml]
    end

    get '/sdr/objects/:druid/content/:filename' do
      content_file = Stanford::StorageServices.retrieve_file(:content, params[:filename], params[:druid], version_param())
      [200, {'content-type' => 'application/octet-stream"'}, content_file.read]
    end

    get '/sdr/objects/:druid/metadata/:filename' do
      metadata_file = Stanford::StorageServices.retrieve_file(:metadata, params[:filename], params[:druid], version_param())
      [200, {'content-type' => 'application/xml'}, metadata_file.read]
    end

    get '/sdr/objects/:druid/manifest/:filename' do
      manifest_file = Stanford::StorageServices.retrieve_file(:manifest, params[:filename], params[:druid], version_param())
      [200, {'content-type' => 'application/xml'}, manifest_file.read]
    end

      post '/sdr/objects/:druid/cm-inv-diff' do
      request.body.rewind
      cmd_xml = request.body.read

      diff = Stanford::StorageServices.compare_cm_to_version_inventory(cmd_xml, params[:druid], version_param())
      [200, {'content-type' => 'application/xml'}, diff.to_xml]
    end

    post '/sdr/objects/:druid/cm-adds' do
      request.body.rewind
      cmd_xml = request.body.read

      additions = Stanford::StorageServices.cm_version_additions(cmd_xml, params[:druid], version_param())
      [200, {'content-type' => 'application/xml'}, additions.to_xml]
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

    def version_param()
      params[:version] ? params[:version].to_i : nil
    end
    
  end
end
