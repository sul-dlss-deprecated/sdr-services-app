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
    configure :local, :development do
      register Sinatra::Reloader
    end
    configure do
      mime_type :plain, 'text/plain'
      mime_type :json, 'application/json'
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

    # @method get_repository_archives
    # @param repository [String] Repository-ID, such as 'sdr', 'dpn', etc. [required]
    # @return a set of archive records
    # @example
    #    /archives/repositories/sdr
    #    /archives/repositories/dpn
    get '/archives/repositories/:repo' do
      archives = Sdr::ArchiveCatalogSQL::DigitalObject.where(:home_repository => params[:repo])
      response.body = archives.map{|a| a.values }.to_json
    end

    # @method get_object_archives
    # @param id [String] Digital-Object-ID, such as DRUID-ID, DPN-ID, etc. [required]
    # @return a set of archive records
    # @example
    #    /archives/objects/druid:jq937jp0017
    #    /archives/objects/jq937jp0017
    get '/archives/objects/:id' do
      id = SDR_DRUID_REGEX.match(params[:id]).to_s || params[:id]
      archives = Sdr::ArchiveCatalogSQL::DigitalObject.where(:digital_object_id => id)
      response.body = archives.map{|a| a.values }.to_json
    end

  end

end


