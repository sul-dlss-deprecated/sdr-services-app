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
      if params.has_key?('signature')
        signature = Stanford::StorageServices.retrieve_file_signature('content', params[:filename], params[:druid], version_param())
        [200, {'content-type' => 'application/xml'}, signature.to_xml]
      else
        content_file = Stanford::StorageServices.retrieve_file('content', params[:filename], params[:druid], version_param())
        [200, {'content-type' => 'application/octet-stream"'}, content_file.read]
      end
    end

    get '/sdr/objects/:druid/metadata/:filename' do
      if params.has_key?('signature')
        signature = Stanford::StorageServices.retrieve_file_signature('metadata', params[:filename], params[:druid], version_param())
        [200, {'content-type' => 'application/xml'}, signature.to_xml]
      else
        metadata_file = Stanford::StorageServices.retrieve_file('metadata', params[:filename], params[:druid], version_param())
        [200, {'content-type' => 'application/xml'}, metadata_file.read]
      end
    end

    get '/sdr/objects/:druid/manifest/:filename' do
      if params.has_key?('signature')
        signature = Stanford::StorageServices.retrieve_file_signature('manifest', params[:filename], params[:druid], version_param())
        [200, {'content-type' => 'application/xml'}, signature.to_xml]
      else
        manifest_file = Stanford::StorageServices.retrieve_file('manifest', params[:filename], params[:druid], version_param())
        [200, {'content-type' => 'application/xml'}, manifest_file.read]
      end
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
        
    def self.new(*)
      super
    end

    def version_param()
      (params[:version].nil? || params[:version].strip.empty?) ? nil : params[:version].to_i
    end
    
  end
end
