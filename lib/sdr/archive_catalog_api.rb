require 'sinatra'
require 'sinatra/advanced_routes'
require 'sinatra/namespace'
require_relative 'archive_catalog_sql'
#require_relative 'archive_catalog_mongo'

# json-schema for description and validation of REST json data.
# http://tools.ietf.org/id/draft-zyp-json-schema-03.html
# http://tools.ietf.org/html/draft-zyp-json-schema-03
require 'multi_json'
require 'json-schema'

module Sdr

  # This API provides a RESTful interface to the Archive Catalog for the
  # Stanford Digital Repository.  This is SDR metadata, primarily data
  # for tracking replication of objects in the preservation core.
  #
  class ArchiveCatalogAPI < Sinatra::Base

    # Register extensions
    register Sinatra::AdvancedRoutes
    register Sinatra::Namespace

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
    end

    configure :local, :development do
      register Sinatra::Reloader
    end

    helpers do

      def digital_object_from_params(params)
        {
            :digital_object_id => parse_object_id(params[:id]),
            :home_repository => params[:repo]
        }
      end

      def digital_object_from_body(request)
        request.body.rewind
        data = request.body.read
        unless validate_json(data, @@digital_object_schema)
          error 400, "Malformed json request, must conform to json-schema:\n#{@@digital_object_schema}"
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

    end


    before do
      # default response is json
      content_type :json
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


    def format_error_message(msg_prefix=nil)
      _datetime = DateTime.now.strftime('ERROR [%d/%b/%Y %H:%M:%S]')
      _error = env['sinatra.error']
      msg = msg_prefix ? "#{_datetime} - info    - #{msg_prefix}\n" : ''
      msg += "#{_datetime} - message - #{_error.class} - #{_error.message}\n"
      msg += "#{_datetime} - request - #{request.url}\n"
      msg += "#{_datetime} - params  - #{request.params.to_s}\n"
      return msg
    end

    @show_exceptions = Sinatra::ShowExceptions.new(self)

    error Sequel::DatabaseError do
      @error = env['sinatra.error']
      env['rack.errors'].write(format_error_message)  # log error
      body @show_exceptions.pretty(env, @error)
      status 500
    end


    namespace "/archive/digital_objects" do

      # @method get_archive_digital_object_repositories
      # @return a set of repository identifiers
      # @example
      #   SDR_ROUTE='/archive/digital_objects/repositories'
      #   curl -v -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
      # response:
      #   ["sdr"]
      get '/repositories' do
        results = ArchiveCatalogSQL::DigitalObject.select(:home_repository).distinct
        response.body = results.map{|i| i[:home_repository]}.to_json
      end

      # @method get_archive_digital_object_objects
      # @return a set of digital objects
      # @example
      #   SDR_ROUTE='/archive/digital_objects/objects'
      #   curl -v -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
      # response:
      #   [{"digital_object_id":"druid:bb002mz7474","home_repository":"sdr"}]
      get '/objects' do
        # Return everything about the objects, including the :home_repository.
        # digital_object_id is a primary key, so .distinct is not required here.
        results = ArchiveCatalogSQL::DigitalObject.all
        response.body = results.map{|i| i.values}.to_json
        # TODO: paginate a large result set
        # TODO: return a 206 Partial Content
        # TODO: add yaml note: Partial sets can be managed with Range headers.
        # The server is returning partial data of the size requested. Used in response to
        # a request specifying a Range header. The server must specify the range
        # included in the response with the Content-Range header.
      end

      # @method get_archive_digital_object_repository_object
      # @param home_repository [String] use values in /archive/repositories [required]
      # @param digital_object_id [String] Digital-Object-ID, such as DRUID-ID, DPN-ID, etc. [required]
      # @return a digital object record
      # @example
      #   SDR_ROUTE='/archive/digital_objects/sdr/druid:bb002mz7474'
      #   curl -v -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
      get '/:repo/:id' do
        begin
          digital_object = digital_object_from_params(params)
          results = ArchiveCatalogSQL::DigitalObject.where(digital_object)
          response.body = results.map{|i| i.values}.to_json
        rescue
          error 404, "Did not find #{params[:id]} in the #{params[:repo]} repository."
        end
      end

      # @method put_archive_digital_objects_repository_object
      # @param home_repository [String] use values in /archive/repositories
      # @param digital_object_id [String] Digital-Object-ID, such as DRUID-ID, DPN-ID, etc. [required]
      # @return an HTTP status for PUT success (201 created, 204 exists) or failure (400 or 500)
      # @example
      #  SDR_DATA='{"digital_object_id": "druid:bb002mz7474", "home_repository": "sdr"}'
      #  SDR_ROUTE='/archive/digital_objects/sdr/druid:bb002mz7474'
      #  curl -v -X PUT -H "Content-Type: application/json" --data "${SDR_DATA}" \
      #       -u ${SDR_USER}:${SDR_PASS} http://${SDR_HOST}:${SDR_PORT}${SDR_ROUTE}
      put '/:repo/:id' do

        #binding.pry

        # PUT: Store the Entity-Body at the URL
        digital_object_params = digital_object_from_params(params)
        digital_object_data = digital_object_from_body(request)
        unless digital_object_data == digital_object_params
          error 400, "URI does not match json data: #{digital_object_data}"
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
            #halt 201, '/archive/:repo/object/:id'
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
                #halt 201, '/archive/:repo/object/:id'
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

    end

    # # @method get_archive_repository_objects
    # # @param repo [String] use values in /archive/repositories
    # # @return a set of archive repository records
    # # @example
    # #    /archive/sdr/objects
    # get '/archive/:repo/objects' do
    #   #id = @@sdr_druid_regex.match(params[:id]).to_s || params[:id]
    #   repo = params[:repo]
    #   case repo
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


