require 'sinatra'
require_relative 'pagination'
require_relative 'archive_catalog_sql'
#require_relative 'archive_catalog_mongo'

# json-schema for description and validation of REST json data.
# http://tools.ietf.org/id/draft-zyp-json-schema-03.html
# http://tools.ietf.org/html/draft-zyp-json-schema-03
require 'multi_json'
require 'json-schema'

# xml serialization
require 'active_support'
require 'active_support/core_ext'


module Sdr

  # This API provides a RESTful interface to the Archive Catalog for the
  # Stanford Digital Repository.  This is SDR metadata, primarily data
  # for tracking replication of objects in the preservation core.
  #
  class ArchiveCatalogAPI < Sinatra::Base

    # Register extensions
    register Sinatra::Pagination
    #register Sinatra::Namespace  # yard doesn't document namespace routes.

    # http://www.sinatrarb.com/configuration.html
    # See Sinatra-error-handling for explanation of exception behavior
    configure do
      enable :logging
      # Don't add backtraces to STDERR for an exception raised by a route or filter.
      disable :dump_errors
      # Exceptions are rescued and mapped to error handlers which typically
      # set a 5xx status code and render a custom error page.
      disable :raise_errors
      # Use custom error blocks, see below.
      disable :show_exceptions
      mime_type :plain, 'text/plain'
      mime_type :json, 'application/json'
      mime_type :xml, 'application/xml'
    end

    configure :local, :development do
      register Sinatra::Reloader
      require 'sinatra/advanced_routes'
      register Sinatra::AdvancedRoutes
    end

    helpers do

      def digital_object_from_params(params)
        {
            :digital_object_id => parse_object_id(params[:digital_object_id]),
            :home_repository => params[:home_repository]
        }
      end

      def digital_object_from_body(request)
        request.body.rewind
        data = request.body.read
        unless validate_json(data, @@digital_object_schema)
          error 422, "Malformed json request, must conform to json-schema:\n#{@@digital_object_schema}"
        end
        return MultiJson.load(data, {:symbolize_keys => true})
      end

      def parse_object_id(id)
        druid_id = @@sdr_druid_regex.match(id).to_s
        if druid_id
          id = "druid:#{druid_id}" # ensure it begins with 'druid:'
        end
        return id
      end

      # Validate JSON object against a JSON schema.
      # @note schema is only validated after json data fails to validate.
      # @param [String] jsonData a json string that will be parsed by MultiJson.load
      # @param [String] jsonSchemaString a json schema string that will be parsed by MultiJson.load
      # @param [boolean] list set it true for jsonObj array of items to validate against jsonSchemaString
      def validate_json(jsonData, jsonSchemaString, list=false)
        schemaVer = :draft3
        jsonObj = MultiJson.load(jsonData)
        jsonSchema = MultiJson.load(jsonSchemaString)
        JSON::Validator.validate(jsonSchema, jsonObj, :list => list, :version => schemaVer)
        #JSON::Validator.fully_validate(jsonSchema, jsonObj, :list => list, :version => schemaVer, :validate_schema => true)
      end

      def format_error_message(msg_prefix=nil)
        _datetime = DateTime.now.strftime('ERROR [%d/%b/%Y %H:%M:%S]')
        _error = env['sinatra.error']
        msg = msg_prefix ? "#{_datetime} - info    - #{msg_prefix}\n" : ''
        msg += "#{_datetime} - message - #{_error.class} - #{_error.message}\n"
        msg += "#{_datetime} - request - #{request.url}\n"
        msg += "#{_datetime} - params  - #{request.params.to_s}\n"
        return msg
      end

      def response_negotiation(obj, options={})
        json_idx = env['HTTP_ACCEPT'] =~ /json/i || 999
        xml_idx  = env['HTTP_ACCEPT'] =~ /xml/i  || 999
        if json_idx < xml_idx
          # respond with json, if it is explicitly requested prior to xml
          content_type :json
          response.body = this_json(obj, options)
        elsif xml_idx < json_idx
          # respond with xml, if it is explicitly requested prior to json
          content_type :xml
          response.body = this_xml(obj, options)
        else
          # default to json
          content_type :json
          response.body = this_json(obj, options)
        end
      end

      def this_json(obj, options={})
        options.merge!({:pretty => true})
        MultiJson.dump(obj, options)
      end
      def this_xml(obj, options={})
        obj.to_xml(options) # from activesupport/core_ext
      end

    end

    before do
    end


    @@sdr_druid_regex = Regexp.new '[[:lower:]]{2}[[:digit:]]{3}[[:lower:]]{2}[[:digit:]]{4}'

    @@digital_object_schema = <<-END_JSON_SCHEMA_STR
{
  "type":"object",
  "title":"Digital Object Identifier",
  "description":"An object in a digital repository.",
  "additionalProperties":false,
  "properties":{
    "digital_object_id":{ "type":"string", "required": true },
    "home_repository":{ "type":"string", "required": true }
  }
}
END_JSON_SCHEMA_STR


    # TODO: define the archive catalog routes, see example client calls in:
    # TODO: See https://github.com/sul-dlss/sdr-replication/blob/master/lib/replication/archive_catalog.rb
    # TODO: Code a simple client for the endpoints defined in the services_api.
    # TODO: Note that code in replication/archive_catalog.rb is WAY TOO GENERIC.
    # TODO: See also DOR workflow code at
    # TODO: https://github.com/sul-dlss/dor-workflow-service/blob/master/lib/dor/services/workflow_service.rb


    @show_exceptions = Sinatra::ShowExceptions.new(self)

    error Sequel::DatabaseError do
      @error = env['sinatra.error']
      env['rack.errors'].write(format_error_message)  # log error
      body @show_exceptions.pretty(env, @error)
      status 500
    end


    # @!macro [attach] get
    #   @overload GET "$1"
    #
    # @method get_archive_digital_objects_repositories
    # @return a set of repository identifiers
    # @example
    #   SDR_ROUTE='/archive/digital_objects/repositories'
    #   curl -v -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
    # response:
    #   ["sdr","etc"]
    get '/archive/digital_objects/repositories' do
      results = ArchiveCatalogSQL::DigitalObject.select(:home_repository).distinct
      response_negotiation(results.map{|i| i[:home_repository]}, {:root => 'repositories'})
    end

    # @method get_archive_digital_objects_objects
    # @return a set of digital objects
    # @example
    #   request:
    #     SDR_ROUTE='/archive/digital_objects/objects'
    #     curl -v -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
    #   response:
    #     [{"digital_object_id":"druid:bb002mz7474","home_repository":"sdr"},
    #      {"digital_object_id":"druid:jq937jp0017","home_repository":"sdr"}]
    # @note response status 206 indicates the response is paginated[https://developer.github.com/v3/#pagination]
    get '/archive/digital_objects/objects' do
      # Return everything about the objects, including the :home_repository.
      # digital_object_id is a primary key, so .distinct is not required here.
      results = http_pagination(ArchiveCatalogSQL::DigitalObject.select)
      response_negotiation(results.map{|i| i.values}, {:root => 'digital_objects'})
      status 206 unless results.page_count == 1
    end

    # @method get_archive_digital_objects_home_repository
    # @param home_repository [String] use values in /archive/repositories [required]
    # @return a set of digital objects in home_repository
    # @example
    #   request:
    #     SDR_ROUTE='/archive/digital_objects/sdr'
    #     curl -v -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
    #   response:
    #     [{"digital_object_id":"druid:bb002mz7474","home_repository":"sdr"},
    #      {"digital_object_id":"druid:jq937jp0017","home_repository":"sdr"}]
    # @note response data can be paginated, @see https://developer.github.com/v3/#pagination
    get '/archive/digital_objects/:home_repository' do
      begin
        dataset = ArchiveCatalogSQL::DigitalObject.where(:home_repository => params[:home_repository])
        results = http_pagination(dataset)
        if results.first.nil?
          error 404, "Did not find any digital objects in the #{params[:home_repository]} repository."
        end
        response_negotiation(results.map{|i| i.values}, {:root => 'digital_objects'})
      rescue
        error 500, "Failed to process the #{params[:home_repository]} repository."
      end
    end

    # @method get_archive_digital_objects_home_repository_digital_object_id
    # @param home_repository [String] use values in /archive/repositories [required]
    # @param digital_object_id [String] Digital-Object-ID, such as DRUID-ID, DPN-ID, etc. [required]
    # @return a digital object record
    # @example
    #   request:
    #     SDR_ROUTE='/archive/digital_objects/sdr/druid:bb002mz7474'
    #     curl -v -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
    #   response:
    #     [{"digital_object_id":"druid:bb002mz7474","home_repository":"sdr"}]
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

    # @!macro [attach] put
    #   @overload PUT "$1"
    #
    # @method put_archive_digital_objects_home_repository_digital_object_id
    # @param home_repository [String] use values in /archive/repositories
    # @param digital_object_id [String] Digital-Object-ID, such as DRUID-ID, DPN-ID, etc. [required]
    # @return an HTTP status for PUT success (201 created, 204 exists) or failure (400+)
    # @example
    #  SDR_DATA='{"digital_object_id": "druid:bb002mz7474", "home_repository": "sdr"}'
    #  SDR_ROUTE='/archive/digital_objects/sdr/druid:bb002mz7474'
    #  curl -v -X PUT -H "Content-Type: application/json" --data "${SDR_DATA}" \
    #       -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
    put '/archive/digital_objects/:home_repository/:digital_object_id' do

      #binding.pry

      # PUT: Store the Entity-Body at the URL
      digital_object_params = digital_object_from_params(params)
      digital_object_data = digital_object_from_body(request)
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
            halt 201, {'Location' => request.route}, 'Digital object created.'
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
          status 204
          #halt 201, '/archive/:home_repository/object/:digital_object_id'
          #halt 202, {'Location' => "/messages/#{message.id}"}, ''
        else
          # The new representation should replace the existing representation.
          # A partial update could be a PATCH request, whereas a PUT must entirely
          # replace the resource content at this route. A PUT is idempotent.
          begin
            obj.delete
            success = ArchiveCatalogSQL::DigitalObject.insert(digital_object_data) == 0
            if success
              status 201
              # TODO
              #halt 201, '/archive/:home_repository/object/:digital_object_id'
              #halt 202, {'Location' => "/messages/#{message.id}"}, ''
            else
              error
            end

          rescue
            #TODO: ony catch Sequel exceptions here?
            error 500
          end
        end
      end
    end


    # # @method get_archive_repository_objects
    # # @param home_repository [String] use values in /archive/repositories
    # # @return a set of archive repository records
    # # @example
    # #    /archive/sdr/objects
    # get '/archive/:home_repository/objects' do
    #   #id = @@sdr_druid_regex.match(params[:id]).to_s || params[:id]
    #   home_repository = params[:home_repository]
    #   case home_repository
    #     when 'sdr'
    #       objects = ArchiveCatalogSQL::SdrObject.all
    #     else
    #       # fall back to generic table of all digital objects
    #       objects = ArchiveCatalogSQL::DigitalObject.all
    #   end
    #
    #   # TODO: paginate huge result sets
    #
    #   response.body = objects.map{|a| a.values }.to_json
    #   # begin
    #   #   response.body = objects.map{|a| a.values }.to_json
    #   # rescue
    #   #   halt 404, "Unable to find object: #{id}"
    #   # end
    # end

  end

end


