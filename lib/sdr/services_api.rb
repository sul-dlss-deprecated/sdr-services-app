require 'moab_stanford'

module Sdr
  class ServicesApi < Sinatra::Base

    helpers do
      def version_param()
        (params[:version].nil? || params[:version].strip.empty?) ? nil : params[:version].to_i
      end

      def file_id_param()
        # request.path_info.  split('/')[5..-1].join('/')
        params[:splat].first
      end

      def signature_param()
        if (params[:signature].nil? || params[:signature].strip.empty?)
          nil
        elsif params[:signature].split(',').size == 3
          size,md5,sha1 = params[:signature].split(',')
          FileSignature.new(:size=>size,:md5=>md5,:sha1=>sha1)
        else
          nil
        end
      end

      def retrieve_file(druid, category, file_id, version, signature)
        if file_id == []
          [400, "file id not specified"]
        else
          if not signature.nil?
            content_file = Stanford::StorageServices.retrieve_file_using_signature(category, signature , druid, version)
          else
            content_file = Stanford::StorageServices.retrieve_file(category, file_id, druid, version)
          end
          # [200, {'content-type' => 'application/octet-stream'}, content_file.read]
          send_file content_file, {:disposition => :attachment , :filename => Pathname(file_id).basename }
        end
      end

      def file_list(druid, category, version)
        title = "Object #{druid} - #{category}#{version ? ' - Version '+version : ''}"
        ul = Array.new
        file_group = Stanford::StorageServices.retrieve_file_group(category, druid, version)
        file_group.path_hash.each do |file_id,signature|
          href = url("/sdr/objects/#{druid}/#{category}/#{file_id}?signature=#{signature.fixity.join(',')}")
          ul << "<li><a href='#{href}'>#{file_id}</a></li>"
        end
        list = ul.join("\n")
        "<html><head><title>#{title}</title></head><body><ul>\n#{list}\n</ul></body></html>"
      end

      def menu(druid, version)
        title = "Object #{druid}#{version ? ' - Version '+version : ''}"
        vopt = version ? "?version=#{version}" : ""
        ul = Array.new
        href = url("/sdr/objects/#{druid}/current_version")
        ul << "<li><a href='#{href}'>get currentversion</a></li>"
        href = url("/sdr/objects/#{druid}/version_metadata")
        ul << "<li><a href='#{href}'>get version metadata#{vopt}</a></li>"
        href = url("/sdr/objects/#{druid}/version_differences?base=0&compare=1")
        ul << "<li><a href='#{href}'>get difference between versions 0 and 1</a></li>"
        href = url("/sdr/objects/#{druid}/list/content#{vopt}")
        ul << "<li><a href='#{href}'>get content list</a></li>"
        href = url("/sdr/objects/#{druid}/list/metadata#{vopt}")
        ul << "<li><a href='#{href}'>get metadata list</a></li>"
        href = url("/sdr/objects/#{druid}/list/manifests#{vopt}")
        ul << "<li><a href='#{href}'>get manifest list</a></li>"
        list = ul.join("\n")
        "<html><head><title>#{title}</title></head><body><ul>\n#{list}\n</ul></body></html>\n"
      end

    end

    # TODO add exception logging
    get '/sdr/objects' do 
      'ok'
    end

    get '/sdr/objects/:druid' do
      [200, {'content-type' => 'text/html'}, menu(params[:druid], version_param)]
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

    get '/sdr/objects/:druid/list/:category' do
      [200, {'content-type' => 'text/html'}, file_list( params[:druid], params[:category], version_param)]
    end

    get '/sdr/objects/:druid/content/*' do
      retrieve_file(params[:druid],'content',file_id_param, version_param, signature_param)
    end

    get '/sdr/objects/:druid/metadata/*' do
      retrieve_file(params[:druid],'metadata',file_id_param, version_param, signature_param)
    end

    get '/sdr/objects/:druid/manifest/*' do
      retrieve_file(params[:druid],'manifest',file_id_param, version_param, signature_param)
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


  end

end
