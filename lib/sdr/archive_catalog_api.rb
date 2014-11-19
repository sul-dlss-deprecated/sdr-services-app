# TODO: define the archive catalog routes, see example client calls in:
# TODO: See https://github.com/sul-dlss/sdr-replication/blob/master/lib/replication/archive_catalog.rb
# TODO: Code a simple client for the endpoints defined in the services_api.
# TODO: Note that code in replication/archive_catalog.rb is WAY TOO GENERIC.
# TODO: See also DOR workflow code at
# TODO: https://github.com/sul-dlss/dor-workflow-service/blob/master/lib/dor/services/workflow_service.rb


require_relative 'sdr_base'
require_relative 'pagination'
require_relative 'archive_catalog_sql'
#require_relative 'archive_catalog_mongo'


module Sdr

  # This API provides a REST interface to the Archive Catalog for the
  # Stanford Digital Repository.  This is SDR metadata, primarily data
  # for tracking replication of objects in the preservation core.
  #
  class ArchiveCatalogAPI < Sdr::Base

    # Register extensions
    register Sinatra::Pagination

    @@sdr_druid_regex = Regexp.new '[[:lower:]]{2}[[:digit:]]{3}[[:lower:]]{2}[[:digit:]]{4}'

    @@schema_path = File.join(File.absolute_path(File.dirname(__FILE__)), 'schemas')
    begin
      schema_file_path = File.join(@@schema_path, 'archive_digital_object.json')
      @@digital_object_json_schema = File.read(schema_file_path)
    rescue
      puts "Failed to read schema file!"
    end
    begin
      schema_file_path = File.join(@@schema_path, 'archive_digital_object.xsd')
      @@digital_object_xml_schema = File.read(schema_file_path)
    rescue
      puts "Failed to read schema file!"
    end

    helpers do

      def digital_object_from_params(params)
        {
            :digital_object_id => parse_object_id(params[:digital_object_id]),
            :home_repository => params[:home_repository]
        }
      end

      def digital_object_from_body
        request.body.rewind
        data = request.body.read
        begin
          if request.content_type =~ /json/i
            unless validate_json(data, @@digital_object_json_schema)
              error 422, "Malformed json, must conform to json-schema:\n#{@@digital_object_json_schema}"
            end
            obj = MultiJson.load(data, {:symbolize_keys => true})
            obj[:digital_object_id] = parse_object_id(obj[:digital_object_id])
            return obj
          elsif request.content_type =~ /xml/i
            unless validate_xml(data, @@digital_object_xml_schema)
              error 422, "Malformed xml, must conform to xml-schema:\n#{@@digital_object_xml_schema}"
            end
            xml_obj = Hash.from_xml(data)
            obj = xml_obj['digital_object'].symbolize_keys
            obj[:digital_object_id] = parse_object_id(obj[:digital_object_id])
            return obj
          else
            # 415 (Unsupported Media Type)
            halt 415, "PUT accepts text/plain or application/json content, not: #{request.content_type}"
          end
        rescue
          error 500, "Failed to parse request body: #{data}"
        end
      end

      def parse_object_id(id)
        druid_id = @@sdr_druid_regex.match(id).to_s
        if druid_id
          id = "druid:#{druid_id}" # ensure it begins with 'druid:'
        end
        return id
      end

    end

    # generic processing prior to route processing
    before do
    end

    error Sequel::DatabaseError do
      @error = env['sinatra.error']
      env['rack.errors'].write(format_error_message)  # log error
      body @show_exceptions.pretty(env, @error)
      status 500
    end

    error do
      msg = format_error_message
      #logger.error "Unexpected Error:\n#{msg}"
      env['rack.errors'].write(msg)  # log error
      @error = env['sinatra.error']
      body $show_exceptions.pretty(env, @error)
      status 500
    end

    # @!group DIGITAL_OBJECTS

    # @method get_archive_digital_objects
    # @return a set of digital objects (can be empty, can be paginated)
    # @example
    #   request:
    #     SDR_ROUTE='/archive/digital_objects'
    #     curl -v -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
    #   response:
    #     status 200: [
    #                     {
    #                         "digital_object_id": "druid:bb002mz7474",
    #                         "home_repository": "sdr"
    #                     },
    #                     {...}
    #                 ]
    #     status 206: result set is paginated
    # @note response status 206 indicates pagination[https://developer.github.com/v3/#pagination]
    get '/archive/digital_objects' do
      begin
        dataset = ArchiveCatalogSQL::DigitalObject.select
        results = http_pagination(dataset)
        response_negotiation(results.map{|i| i.values}, {:root => 'digital_objects'})
        status 206 unless results.page_count == 1
      rescue
        error 500, "Failed to process the digital objects dataset."
      end
    end

    # @!macro [attach] sinatra.get
    #   @overload GET "$1"
    #
    # @method get_archive_digital_objects_repositories
    # @return a set of repository identifiers (can be empty)
    # @example
    #   request:
    #     SDR_ROUTE='/archive/digital_objects/repositories'
    #     curl -v -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
    #   response:
    #     status 200: [
    #                  "sdr",
    #                  "..."
    #                 ]
    get '/archive/digital_objects/repositories' do
      begin
        results = ArchiveCatalogSQL::DigitalObject.select(:home_repository).distinct
        response_negotiation(results.map{|i| i[:home_repository]}, {:root => 'repositories'})
      rescue
        error 500, "Failed to process the digital objects dataset."
      end
    end

    # @method get_archive_digital_objects_home_repository
    # @param home_repository [String] a value in /archive/digital_objects/repositories [required]
    # @return a set of digital objects in home_repository (can be empty, can be paginated)
    # @example
    #   request:
    #     SDR_ROUTE='/archive/digital_objects/sdr'
    #     curl -v -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
    #   response:
    #     status 200: [
    #                     {
    #                         "digital_object_id": "druid:bb002mz7474",
    #                         "home_repository": "sdr"
    #                     },
    #                     {...}
    #                 ]
    #     status 206: result set is paginated
    # @note response status 206 indicates pagination[https://developer.github.com/v3/#pagination]
    get '/archive/digital_objects/:home_repository' do
      begin
        dataset = ArchiveCatalogSQL::DigitalObject.where(:home_repository => params[:home_repository])
        results = http_pagination(dataset)
        response_negotiation(results.map{|i| i.values}, {:root => 'digital_objects'})
        status 206 unless results.page_count == 1
      rescue
        error 500, "Failed to process the #{params[:home_repository]} repository."
      end
    end

    # @method get_archive_digital_objects_home_repository_digital_object_id
    # @param home_repository [String] a value in /archive/digital_objects/repositories [required]
    # @param digital_object_id [String] Digital-Object-ID, such as DRUID-ID, DPN-ID, etc. [required]
    # @return a digital object record
    # @example
    #   request:
    #     SDR_ROUTE='/archive/digital_objects/sdr/druid:bb002mz7474'
    #     curl -v -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
    #   response:
    #     status 200: [
    #                     {
    #                         "digital_object_id": "druid:bb002mz7474",
    #                         "home_repository": "sdr"
    #                     }
    #                 ]
    #     status 404: Not found (this could be the most useful response of this route)
    # @note response data should be a single item, results are not paginated
    get '/archive/digital_objects/:home_repository/:digital_object_id' do
      begin
        digital_object = digital_object_from_params(params)
        results = ArchiveCatalogSQL::DigitalObject.where(digital_object)
        if results.first.nil?
          error 404, "Did not find #{params[:digital_object_id]} in the #{params[:home_repository]} repository."
        end
        response_negotiation(results.map{|i| i.values}, {:root => 'digital_objects'})
      rescue
        error 500, "Failed to process #{params[:digital_object_id]} in the #{params[:home_repository]} repository."
      end
    end

    # @!macro [attach] sinatra.head
    #   @overload HEAD "$1"
    #
    # @method head_archive_digital_objects_home_repository_digital_object_id
    # @param home_repository [String] a value in /archive/digital_objects/repositories [required]
    # @param digital_object_id [String] Digital-Object-ID, such as DRUID-ID, DPN-ID, etc. [required]
    # @return the status header is the most useful value returned by this route
    # @example
    #   request:
    #     SDR_ROUTE='/archive/digital_objects/sdr/druid:bb002mz7474'
    #     curl -v -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
    #   response:
    #     status 200: The digital object exists, data is available via GET
    #     status 404: Not found (this could be the most useful response of this route)
    head '/archive/digital_objects/:home_repository/:digital_object_id' do
      begin
        digital_object = digital_object_from_params(params)
        results = ArchiveCatalogSQL::DigitalObject.where(digital_object)
        if results.first.nil?
          status 404
        end
        status 200
      rescue
        status 500
      end
    end

    # @!macro [attach] sinatra.put
    #   @overload PUT "$1"
    #
    # @method put_archive_digital_objects_home_repository_digital_object_id
    # @param home_repository [String] a new value or existing value in /archive/digital_objects/repositories [required]
    # @param digital_object_id [String] Digital-Object-ID, such as DRUID-ID, DPN-ID, etc. [required]
    # @return an HTTP status for PUT success (201 created, 204 exists) or failure (400+)
    # @example
    #  SDR_DATA='{"digital_object_id": "druid:bb002mz7474", "home_repository": "sdr"}'
    #  SDR_ROUTE='/archive/digital_objects/sdr/druid:bb002mz7474'
    #  curl -v -X PUT -H "Content-Type: application/json" --data "${SDR_DATA}" \
    #       -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
    put '/archive/digital_objects/:home_repository/:digital_object_id' do
      # PUT: Store the Entity-Body at the URL
      digital_object_params = digital_object_from_params(params)
      digital_object_data = digital_object_from_body
      unless digital_object_data == digital_object_params
        error 422, "URI does not match json data: #{digital_object_data}"
      end
      # Try to find an existing object.
      objects = ArchiveCatalogSQL::DigitalObject.where(digital_object_data).all
      unless objects.length < 2
        # digital_object_id is a primary key, so we can only get 0 or 1 results
        error 500, "Too many matching objects: #{objects.map{|i| i.values}.to_json}"
      end
      if objects.length == 0
        # If the target resource does not have a current representation and the
        # PUT successfully creates one, then the origin server MUST inform the
        # user agent by sending a 201 (Created) response.
        begin
          success = ArchiveCatalogSQL::DigitalObject.insert(digital_object_data) == 0
          if success
            # 201 (Created)
            halt 201, {'Location' => request.path}, 'Digital object created.'
          else
            error 500
          end
        rescue
          #TODO: ony catch Sequel exceptions here?
          error 500
        end
      else
        # If the target resource does have a current representation and that representation
        # is successfully modified in accordance with the state of the request
        # representation, then either a 200 (OK) or 204 (No Content) response
        # SHOULD be sent to indicate successful completion of the request.
        obj = objects.first
        if obj.values == digital_object_data
          # The request representation already exists, do nothing.
          # 304 (Not Modified)
          halt 304, {'Location' => request.path}, 'Digital object exists.'
        else
          # Note: should never arrive at this code block, because the
          #       digital_object data would not match the route parameters.
          #
          # The new representation should replace the existing representation.
          # A partial update could be a PATCH request, whereas a PUT must entirely
          # replace the resource content at this route. A PUT is idempotent.
          begin
            obj.delete
            success = ArchiveCatalogSQL::DigitalObject.insert(digital_object_data) == 0
            if success
              # 204 (No Content)
              halt 204, {'Location' => request.path}, ''
            else
              error 500
            end
          rescue
            #TODO: ony catch Sequel exceptions here?
            error 500
          end
        end
      end
    end




    # @!endgroup
    # @!group SDR_OBJECTS






    # @method get_archive_sdr_objects
    # @return a set of SDR objects (can be empty, can be paginated)
    # @example
    #   request:
    #     SDR_ROUTE='/archive/sdr_objects'
    #     curl -v -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
    #   response:
    #     status 200:  [
    #                      {
    #                          "sdr_object_id": "druid:bb002mz7474",
    #                          "object_type": "item",
    #                          "governing_object": "druid:fg586rn4119",
    #                          "object_label": null,
    #                          "latest_version": 1
    #                      },
    #                      {...}
    #                  ]
    #     status 206: result set is paginated
    # @note response status 206 indicates pagination[https://developer.github.com/v3/#pagination]
    get '/archive/sdr_objects' do
      begin
        dataset = ArchiveCatalogSQL::SdrObject.select
        results = http_pagination(dataset)
        response_negotiation(results.map{|i| i.values}, {:root => 'sdr_objects'})
        status 206 unless results.page_count == 1
      rescue
        error 500, "Failed to process the SdrObject dataset."
      end
    end

    # @method get_archive_sdr_objects_sdr_object_id
    # @param sdr_object_id [String] Digital-Repository-Unique-ID (DRUID) [required]
    # @return an SDR object record
    # @example
    #   request:
    #     SDR_ROUTE='/archive/sdr_objects/druid:bb002mz7474'
    #     curl -v -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
    #   response:
    #     status 200:  [
    #                      {
    #                          "sdr_object_id": "druid:bb002mz7474",
    #                          "object_type": "item",
    #                          "governing_object": "druid:fg586rn4119",
    #                          "object_label": null,
    #                          "latest_version": 1
    #                      }
    #                  ]
    #     status 404: No matching digital object found
    # @note response data should be a single item, results are not paginated
    get '/archive/sdr_objects/:sdr_object_id' do
      begin
        sdr_object_id = parse_object_id(params[:sdr_object_id])
        results = ArchiveCatalogSQL::SdrObject.where(:sdr_object_id => sdr_object_id)
        if results.first.nil?
          error 404, "Did not find #{params[:sdr_object_id]}."
        end
        response_negotiation(results.map{|i| i.values}, {:root => 'sdr_objects'})
      rescue
        error 500, "Failed to process #{params[:sdr_object_id]}."
      end
    end



    # @!endgroup






  end

end


