require 'sinatra'
require 'sinatra/advanced_routes'
require_relative 'archive_catalog_sql'
#require_relative 'archive_catalog_mongo'

module Sdr

  # TODO: Add documentation on other object identifiers, such as DPN or Google books.

  # This API provides a RESTful interface to the Archive Catalog for the
  # Stanford Digital Repository.  This is SDR metadata, primarily data
  # for tracking replication of objects in the preservation core.
  #
  # Content is referenced by digital repository unique identifiers (DRUIDs).
  # A DRUID is a unique identifier, such as +'jq937jp0017'+ or +'druid:jq937jp0017'+.
  # The DRUID regex pattern, using posix bracket notation, is:
  #   [[:lower:]]{2}[[:digit:]]{3}[[:lower:]]{2}[[:digit:]]{4}
  #
  # @see https://github.com/sul-dlss/sdr-services-app
  # @see https://github.com/sul-dlss/druid-tools
  #
  class ArchiveCatalogAPI < Sinatra::Base

    use Sdr::ArchiveCatalogSQL
    #use Sdr::ArchiveCatalogMongo

    # Register extensions
    register Sinatra::AdvancedRoutes

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

    before do
      # default response is json
      content_type :json
    end

    SDR_DRUID_REGEX = Regexp.new '[[:lower:]]{2}[[:digit:]]{3}[[:lower:]]{2}[[:digit:]]{4}'


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

    SHOW_EXCEPTIONS = Sinatra::ShowExceptions.new(self)

    error Sequel::DatabaseError do
      @error = env['sinatra.error']
      env['rack.errors'].write(format_error_message)  # log error
      body SHOW_EXCEPTIONS.pretty(env, @error)
      status 500
    end


    # @method get_archive_repositories
    # @return a set of repository identifiers
    # @example
    #    /archive/repositories
    get '/archive/repositories' do
      repos = Sdr::ArchiveCatalogSQL::DigitalObject.select(:home_repository)
      response.body = repos.map{|a| a.values }.to_json
    end

    # @method get_archive_objects
    # @return a complete set of archive object identifiers
    # @example
    #    /archive/objects
    get '/archive/objects' do
      objects = Sdr::ArchiveCatalogSQL::DigitalObject.all
      response.body = objects.map{|a| a.values }.to_json
    end

    # @method get_archive_repository_object
    # @param repo [String] use values in /archive/repositories
    # @param id [String] Digital-Object-ID, such as DRUID-ID, DPN-ID, etc. [required]
    # @return a set of archive records
    # @example
    #    /archive/sdr/objects/druid:bb002mz7474
    get '/archive/:repo/object/:id' do
      #id = SDR_DRUID_REGEX.match(params[:id]).to_s || params[:id]
      repo = params[:repo]
      id = params[:id]
      case repo
        when 'sdr'
          objects = Sdr::ArchiveCatalogSQL::SdrObject.where(:sdr_object_id => id)
        else
          # fall back to generic table of all digital objects
          objects = Sdr::ArchiveCatalogSQL::DigitalObject.where(:digital_object_id => id)
      end
      response.body = objects.map{|a| a.values }.to_json
      # begin
      #   response.body = objects.map{|a| a.values }.to_json
      # rescue
      #   halt 404, "Unable to find object: #{id}"
      # end
    end

  end

end


