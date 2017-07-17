require 'sinatra/base'
require 'sinatra/advanced_routes'
# require 'sinatra/namespace'

# require 'api/authentication'
# require 'api/error_handling'
# require 'api/pagination'

# json-schema for description and validation of REST json data.
# http://tools.ietf.org/id/draft-zyp-json-schema-03.html
# http://tools.ietf.org/html/draft-zyp-json-schema-03
require 'multi_json'
require 'json-schema'

# xml serialization
require 'active_support'
require 'active_support/core_ext'

require 'honeybadger'

module Sdr

  class Base < ::Sinatra::Base
    # register ::Sinatra::Namespace # yard doesn't document namespace routes.
    # register ::Sinatra::ErrorHandling
    # register ::Sinatra::Authentication
    # register ::Sinatra::Pagination
    register Sinatra::AdvancedRoutes

    # Register development extensions
    configure :local, :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
    end

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

    # We want JSON all the time, use our custom error handlers
    # set :show_exceptions, false
    $show_exceptions = Sinatra::ShowExceptions.new(self)

    # Run the following before every API request
    before do
      # content_type :json
      # permit_authentication
    end

    set :public_folder, 'lib/sdr/public'

    use Rack::Auth::Basic, 'Restricted Area' do |username, password|
      [username, password] == [SdrServices::Config.username, SdrServices::Config.password]
    end

    # Global helper methods available to all namespaces
    helpers do
      # # Shortcut to generate json from hash, make it look good
      # def json(json)
      #   MultiJson.dump(json, pretty: true)
      # end
      #
      # # Parse the request body and enforce that it is a JSON hash
      # def parsed_request_body
      #   if request.content_type.include?("multipart/form-data;")
      #     parsed = params
      #   else
      #     parsed = MultiJson.load(request.body, symbolize_keys: true)
      #   end
      #   halt_with_400_bad_request("The request body you provide must be a JSON hash") unless parsed.is_a?(Hash)
      #   return parsed
      # end

      # Validate JSON object against a JSON schema.
      # @note schema is only validated after json data fails to validate.
      # @param [String] jsonString a json string that will be parsed by MultiJson.load
      # @param [String] jsonSchemaString a json schema string that will be parsed by MultiJson.load
      # @param [boolean] list set it true for json array to validate against jsonSchemaString
      def validate_json(jsonString, jsonSchemaString, list=false)
        schemaVer = :draft3
        json_doc = MultiJson.load(jsonString)
        json_schema = MultiJson.load(jsonSchemaString)
        JSON::Validator.validate(json_schema, json_doc, :list => list, :version => schemaVer)
        #JSON::Validator.fully_validate(json_schema, json_doc, :list => list, :version => schemaVer, :validate_schema => true)
      end

      # Validate XML against an XML schema definition (XSD).
      # @param [String] xmlString a xml string that will be parsed by Nokogiri::XML
      # @param [String] xmlSchemaString a xml schema string that will be parsed by Nokogiri::XML::Schema
      def validate_xml(xmlString, xmlSchemaString, root_element=nil)
        xml_doc = Nokogiri::XML(xmlString)
        xml_schema = Nokogiri::XML::Schema(xmlSchemaString)
        if root_element
          errors = xml_schema.validate(xml_doc.xpath("//#{root_element}").first)
        else
          errors = xml_schema.validate(xml_doc)
        end
        errors.empty?
      end

      def response_negotiation(obj, options={})
        json_idx = env['HTTP_ACCEPT'] =~ /json/i || 999
        xml_idx  = env['HTTP_ACCEPT'] =~ /xml/i  || 999
        if json_idx < xml_idx
          # respond with json, if it is explicitly requested prior to xml
          content_type :json
          response.body = obj_to_json(obj, options)
        elsif xml_idx < json_idx
          # respond with xml, if it is explicitly requested prior to json
          content_type :xml
          response.body = obj_to_xml(obj, options)
        else
          # default to json
          content_type :json
          response.body = obj_to_json(obj, options)
        end
      end

      def obj_to_json(obj, options={})
        options.merge!({:pretty => true})
        MultiJson.dump(obj, options)
        #ActiveSupport::JSON.encode(obj, options)
      end

      def obj_to_xml(obj, options={})
        obj.to_xml(options) # from activesupport/core_ext
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

    end

  end
end
