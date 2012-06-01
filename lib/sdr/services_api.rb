require 'moab_stanford'

module Sdr
  class ServicesApi < Sinatra::Base

    helpers do
      def latest_version
        unless @latest_version
          @latest_version = Stanford::StorageServices.current_version(params[:druid])
        end
        @latest_version
      end

      def caption(version)
        "Object = #{params[:druid]} - Version = #{version ? version.to_s : latest_version} of #{latest_version}"
      end

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
        ul = Array.new
        file_group = Stanford::StorageServices.retrieve_file_group(category, druid, version)
        file_group.path_hash.each do |file_id,signature|
          vopt = version ? "?version=#{version}" : ""
          if category =~ /manifest/
            href = url("/sdr/objects/#{druid}/#{category}/#{file_id}#{vopt}")
          else
            href = url("/sdr/objects/#{druid}/#{category}/#{file_id}?signature=#{signature.fixity.join(',')}")
          end
          ul << "<li><a href='#{href}'>#{file_id}</a></li>"
        end
        title = "<title>#{caption(version)} - #{category.capitalize}</title>\n"
        h3 = "<h3>#{caption(version)} - #{category.capitalize}</h3>\n"
        list = "<ul>\n#{ul.join("\n")}\n</ul>\n"
        "<html><head>\n#{title}</head><body>\n#{h3}#{list}</body></html>\n"
      end

      def menu(druid, version)
        vopt = version ? "?version=#{version}" : ""
        ul = Array.new
        href = url("/sdr/objects/#{druid}/list/content#{vopt}")
        ul << "<li><a href='#{href}'>get content list</a></li>"
        href = url("/sdr/objects/#{druid}/list/metadata#{vopt}")
        ul << "<li><a href='#{href}'>get metadata list</a></li>"
        href = url("/sdr/objects/#{druid}/list/manifests#{vopt}")
        ul << "<li><a href='#{href}'>get manifest list</a></li>"
        href = url("/sdr/objects/#{druid}/version_list")
        ul << "<li><a href='#{href}'>get version list</a></li>"

        title = "<title>#{caption(version)}</title>\n"
        h3 = "<h3>#{caption(version)}</h3>\n"
        list = "<ul>\n#{ul.join("\n")}\n</ul>\n"
        "<html><head>\n#{title}</head><body>\n#{h3}#{list}</body></html>\n"
      end

      def version_list
        ul = Array.new
        version_metadata_file = Stanford::StorageServices.version_metadata(params[:druid])
        vm = Moab::VersionMetadata.parse(version_metadata_file.read)
        vm.versions.each do |v|
          v.inspect
          href = url("/sdr/objects/#{params[:druid]}?version=#{v.version_id.to_s}")
          ul << "<li><a href='#{href}'>Version #{v.version_id.to_s} - #{v.description}</a></li>"
        end
        title = "<title>Object = #{params[:druid]} - Versions</title>\n"
        h3 = "<h3>Object = #{params[:druid]} - Versions</h3>\n"
        list = "<ul>\n#{ul.join("\n")}\n</ul>\n"
        "<html><head>\n#{title}</head><body>\n#{h3}#{list}</body></html>\n"
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

    get '/sdr/objects/:druid/version_list' do
      [200, {'content-type' => 'text/html'}, version_list]
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

    get '/sdr/objects/:druid/manifests/*' do
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

    get '/test/file_id_param/*' do
      file_id_param
    end

    def self.new(*)
      super
    end


  end

end
