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

    db_config = YAML.load_file('config/database.yml')

    # configure :development do
    #   register Sinatra::Reloader
    #
    #   # connect to an in-memory database
    #   DB = Sequel.sqlite
    #
    #   # # create an items table
    #   # DB.create_table :items do
    #   #   primary_key :id
    #   #   String :name
    #   #   Float :price
    #   # end
    #   # # create a dataset from the items table
    #   # items = DB[:items]
    #   # # populate the table
    #   # items.insert(:name => 'abc', :price => rand * 100)
    #   # items.insert(:name => 'def', :price => rand * 100)
    #   # items.insert(:name => 'ghi', :price => rand * 100)
    #   # # print out the number of records
    #   # puts "Item count: #{items.count}"
    #   # # print out the average price
    #   # puts "The average price is: #{items.avg(:price)}"
    # end

    configure :test do

      # TODO: resolve conflict in rspec vs. -test platform.

      db_config = db_config['testing']
      DB = Sequel.oracle(:host=>db_config['host'],
                         :port=>db_config['port'],
                         :user=>db_config['user'],
                         :password=>db_config['password'],
                         :database=>db_config['database'])
      # TODO: opts[:privilege] for oracle???
      # http://sequel.jeremyevans.net/rdoc-adapters/classes/Sequel/Oracle/Database.html
      # http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-oracle+
    end

    configure :development do
      db_config = db_config['integration']
      DB = Sequel.oracle(:host=>db_config['host'],
                         :port=>db_config['port'],
                         :user=>db_config['user'],
                         :password=>db_config['password'],
                         :database=>db_config['database'])
    end

    configure :production do
      db_config = db_config['production']
      DB = Sequel.oracle(:host=>db_config['host'],
                         :port=>db_config['port'],
                         :user=>db_config['user'],
                         :password=>db_config['password'],
                         :database=>db_config['database'])
    end

    # Ensure the connection is good on startup, raises exceptions on failure
    puts "#{DB} connected: #{DB.test_connection}"


    # digital_objects 	All SDR and DPN objects preserved in SDR Core
    # digital_object_id 	varchar2(40 byte) 	no 	Either the SDR druid or the DPN UUID
    # home_repository 	varchar2(3 byte) 	no 	The source location of the object/version (sdr or dpn)
    class DigitalObject < Sequel::Model
      #set_primary_key [:digital_object_id]
      #set_primary_key [:category, :title]
    end
    dObj = DigitalObject.all.first
    puts "#{dObj.pk}"

    # sdr_objects 	Inventory of SDR objects preserved in SDR Core
    class SdrObject < Sequel::Model
    end

    # sdr_object_versions 	Inventory of all versions of SDR objects
    class SdrObjectVersion < Sequel::Model(sdr_object_versions)
    end

    # sdr_version_stats 	Size metrics for SDR object versions
    class SdrVersionStat < Sequel::Model(:sdr_version_stats)
    end

    # replicas 	Containerized copies of object/versions (to be) archived to tape
    class Replica < Sequel::Model(:replicas)
    end

    # tape_replicas 	Join table indicating which replicas were archived in which tape archive
    class TapeReplica < Sequel::Model(:tape_replicas)
    end
    # tape_archives 	A container holding multiple replicas which was archived to tape
    class TapeArchive < Sequel::Model(:tape_archives)
    end

    # dpn_objects 	Inventory of objects from DPN that were archived to tape
    class DPNObject < Sequel::Model(:dpn_objects)
    end

    # Views:
    #
    # new_replicas 	Replicas not yet archived to tape 	details
    class NewReplica < Sequel::Model(:new_replicas)
    end

  end

end

