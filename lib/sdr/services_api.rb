require 'moab_stanford'
require 'sys/filesystem'

module Sdr
  class ServicesApi < Sinatra::Base

    # See Sinatra-error-handling for explanation of exception behavior
    configure do
      enable :logging
      disable :raise_errors
      disable :show_exceptions
    end

    use Rack::Auth::Basic, "Restricted Area" do |username, password|
      [username, password] == [SdrServices::Config.username, SdrServices::Config.password]
    end

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

      def subset_param()
        (params[:subset].nil? || params[:subset].strip.empty?) ? 'all' : params[:subset]
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
        elsif params[:signature].split(',').size > 1
          values = params[:signature].split(',')
          signature = FileSignature.new(:size=>values[0])
          values[1..-1].each do |checksum|
            case checksum.size
              when 32
                signature.md5 = checksum
              when 40
                signature.sha1 = checksum
              when 64
                signature.sha256 = checksum
            end
          end
          signature
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
            href = url("/objects/#{druid}/#{category}/#{file_id}#{vopt}")
          else
            signature_value = "#{signature.size.to_s},#{signature.checksums.values[0]}"
            href = url("/objects/#{druid}/#{category}/#{file_id}?signature=#{signature_value}")
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
        href = url("/objects/#{druid}/list/content#{vopt}")
        ul << "<li><a href='#{href}'>get content list</a></li>"
        href = url("/objects/#{druid}/list/metadata#{vopt}")
        ul << "<li><a href='#{href}'>get metadata list</a></li>"
        href = url("/objects/#{druid}/list/manifests#{vopt}")
        ul << "<li><a href='#{href}'>get manifest list</a></li>"
        href = url("/objects/#{druid}/version_list")
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
          href = url("/objects/#{params[:druid]}?version=#{v.version_id.to_s}")
          ul << "<li><a href='#{href}'>Version #{v.version_id.to_s} - #{v.description}</a></li>"
        end
        title = "<title>Object = #{params[:druid]} - Versions</title>\n"
        h3 = "<h3>Object = #{params[:druid]} - Versions</h3>\n"
        list = "<ul>\n#{ul.join("\n")}\n</ul>\n"
        "<html><head>\n#{title}</head><body>\n#{h3}#{list}</body></html>\n"
      end

    end

    error Moab::ObjectNotFoundException do
      [404, request.env['sinatra.error'].message]
    end

    error Moab::FileNotFoundException do
      [404, request.env['sinatra.error'].message]
    end

    error Moab::InvalidMetadataException do
      [400, "Bad Request: Invalid contentMetadata - " + request.env['sinatra.error'].message]
    end

    error do
      errmsg = 'Unexpected Error: ' + request.env['sinatra.error'].message
      logger.error errmsg
      [500, errmsg]
    end

    get '/error_test/object_not_found' do
      raise Moab::ObjectNotFoundException
    end

    get '/error_test/file_not_found' do
      raise Moab::FileNotFoundException
    end

    get '/error_test/invalid_metadata' do
      raise Moab::InvalidMetadataException
    end

    # TODO add exception logging
    get '/objects' do
      logger.info 'logging is working'
      "ok\n"
    end

    get '/objects/:druid' do
      [200, {'content-type' => 'text/html'}, menu(params[:druid], version_param)]
    end

    get '/objects/:druid/current_version' do
      current_version = Stanford::StorageServices.current_version(params[:druid])
      [200, {'content-type' => 'application/xml'}, "<currentVersion>#{current_version.to_s}</currentVersion>"]
    end

    get '/objects/:druid/version_metadata' do
      version_metadata = Stanford::StorageServices.version_metadata(params[:druid])
      [200, {'content-type' => 'application/xml'}, version_metadata.read]
    end

    get '/objects/:druid/version_list' do
      [200, {'content-type' => 'text/html'}, version_list]
    end

    get '/objects/:druid/version_differences' do
      version_differences = Stanford::StorageServices.version_differences(params[:druid], params[:base].to_i, params[:compare].to_i)
      [200, {'content-type' => 'application/xml'}, version_differences.to_xml]
    end

    get '/objects/:druid/list/:category' do
      [200, {'content-type' => 'text/html'}, file_list( params[:druid], params[:category], version_param)]
    end

    get '/objects/:druid/content/*' do
      retrieve_file(params[:druid],'content',file_id_param, version_param, signature_param)
    end

    get '/objects/:druid/metadata/*' do
      retrieve_file(params[:druid],'metadata',file_id_param, version_param, signature_param)
    end

    get '/objects/:druid/manifest/*' do
      retrieve_file(params[:druid],'manifest',file_id_param, version_param, signature_param)
    end

    get '/objects/:druid/manifests/*' do
      retrieve_file(params[:druid],'manifest',file_id_param, version_param, signature_param)
    end

    get '/objects/:druid/cm-remediate' do
      remediated_cm = Stanford::StorageServices.cm_remediate(params[:druid], version_param())
      [200, {'content-type' => 'application/xml'}, remediated_cm]
    end

    # Both technical-metadata and shelve robots currently make a call to Dor::Itemizable#get_content_diff which:
    # 1. pulls new contentMetadata from Fedora
    # 2. posts that contentMetadata to sdr-service's  cm-inv-diff
    # 3. receives a fileInventoryDifferences report in response
    post '/objects/:druid/cm-inv-diff' do
      request.body.rewind
      cmd_xml = request.body.read
      diff = Stanford::StorageServices.compare_cm_to_version(cmd_xml, params[:druid], subset_param(), version_param())
      [200, {'content-type' => 'application/xml'}, diff.to_xml]
    end

    post '/objects/:druid/cm-adds' do
      request.body.rewind
      cmd_xml = request.body.read
      additions = Stanford::StorageServices.cm_version_additions(cmd_xml, params[:druid], version_param())
      [200, {'content-type' => 'application/xml'}, additions.to_xml]
    end

    get '/objects/:druid/rsync' do
      request.body.rewind
      source_path = Stanford::StorageServices.object_path(params[:druid])
      destination_host = SdrServices::Config.rsync_destination_host
      destination_home = SdrServices::Config.rsync_destination_home
      destination_path = File.join(destination_home,params[:druid].split(/:/).last)
      if destination_host.nil? or destination_host.empty?
        # local copy (for testing purposes)
        # create all directories in the destination path
        `mkdir -p #{destination_path}`
        # note the trailing spaces to avoid creating already existing subdir at the destination
        rsync_cmd = "rsync -a '#{source_path}/' '#{destination_path}/'"
        # use at command to allow immediate response to caller
      else
        `ssh #{destination_host} 'mkdir -p #{destination_path}'`
        rsync_cmd = "rsync -a -e ssh '#{source_path}/' '#{destination_host}:#{destination_path}/'"
      end
      `echo "#{rsync_cmd}" | at now`
      [200, "#{rsync_cmd}\n" ]
    end

    get '/gb_used' do
      gigabye_size = 1024*1024*1024
      storage_mounts = Sys::Filesystem.mounts.select{|mount| SdrServices::Config.storage_filesystems.include?(mount.mount_point) }
      storage_stats = storage_mounts.map{|mount| Sys::Filesystem.stat(mount.mount_point)}
      used = storage_stats.inject(0){|sum,stat| sum + ((stat.blocks.to_f-stat.blocks_available.to_f) *stat.block_size.to_f)/gigabye_size }
      [200, used.round.to_s ]
    end

    get '/test/file_id_param/*' do
      file_id_param
    end

    def self.new(*)
      super
    end


  end

end
