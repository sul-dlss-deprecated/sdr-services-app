require 'yaml'
require 'oci8'
require 'sequel'

# http://sequel.jeremyevans.net/documentation.html
# http://sequel.jeremyevans.net/rdoc/files/README_rdoc.html

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
  class ArchiveCatalogSQL < Sinatra::Base

    APP_ENV = ENV['APP_ENV']
    if ['test','local','development'].include?(APP_ENV)
      require 'pry'
      register Sinatra::Reloader
    end

    def self.log_model_info(m)
      #if ['test','local'].include?(APP_ENV)
      if ['local'].include?(APP_ENV)
        puts "table: #{m.table_name}, columns: #{m.columns}, pk: #{m.primary_key}"
      end
    end

    # local mysql setup with db/mysql_*.sql scripts
    # deployed oracle setup with db/oracle_*.sql scripts
    db_config = YAML.load_file('config/database.yml')
    db_config = db_config[APP_ENV]
    DB = Sequel.mysql(:host=>db_config['host'],
                      :port=>db_config['port'],
                      :user=>db_config['user'],
                      :password=>db_config['password'],
                      :database=>db_config['database'])
    # Ensure the connection is good on startup, raises exceptions on failure
    puts db_config
    puts "#{DB} connected: #{DB.test_connection}"


    # digital_objects 	All SDR and DPN objects preserved in SDR Core
    # digital_object_id 	Either the SDR druid or the DPN UUID
    # home_repository 	The source location of the object/version (sdr or dpn)
    class DigitalObject < Sequel::Model
    end
    ArchiveCatalogSQL.log_model_info(DigitalObject)

    # sdr_objects 	Inventory of SDR objects preserved in SDR Core
    class SdrObject < Sequel::Model
    end
    ArchiveCatalogSQL.log_model_info(SdrObject)

    # sdr_object_versions 	Inventory of all versions of SDR objects
    class SdrObjectVersion < Sequel::Model
    end
    ArchiveCatalogSQL.log_model_info(SdrObjectVersion)

    # sdr_version_stats 	Size metrics for SDR object versions
    class SdrVersionStat < Sequel::Model
    end
    ArchiveCatalogSQL.log_model_info(SdrVersionStat)

    # replicas 	Containerized copies of object/versions (to be) archived to tape
    class Replica < Sequel::Model
    end
    ArchiveCatalogSQL.log_model_info(Replica)

    # tape_replicas 	Join table indicating which replicas were archived in which tape archive
    class TapeReplica < Sequel::Model
    end
    ArchiveCatalogSQL.log_model_info(TapeReplica)

    # tape_archives 	A container holding multiple replicas which was archived to tape
    class TapeArchive < Sequel::Model
    end
    ArchiveCatalogSQL.log_model_info(TapeArchive)

    # dpn_objects 	Inventory of objects from DPN that were archived to tape
    class DpnObject < Sequel::Model
    end
    ArchiveCatalogSQL.log_model_info(DpnObject)

    # Views:
    #
    # new_replicas 	Replicas not yet archived to tape
    class NewReplica < Sequel::Model
    end
    ArchiveCatalogSQL.log_model_info(NewReplica)

  end

end


