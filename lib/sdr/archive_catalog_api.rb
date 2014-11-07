
require_relative 'archive_catalog_sql'
#require_relative 'archive_catalog_mongo'

module Sdr

  # This API provides a RESTful interface to the Archive Catalog for the
  # Stanford Digital Repository.  This is SDR metadata, primarily data
  # for tracking data replication.
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

    # TODO: define the archive catalog routes, see example client calls in:
    # TODO: See https://github.com/sul-dlss/sdr-replication/blob/master/lib/replication/archive_catalog.rb
    # TODO: Code a simple client for the endpoints defined in the services_api.
    # TODO: Note that code in replication/archive_catalog.rb is WAY TOO GENERIC.

  end

end


