require 'logger'
require 'sequel'
require 'yaml'

# Define a class method to paginate through ORM models
# pagination is based on github recommendation, see
# https://developer.github.com/guides/traversing-with-pagination/
# see alternative at http://dev.librato.com/v1/pagination
class Sequel::Model
  def self.page(page, per_page=30, *args)
    # The page number comes as a string from the Sinatra controller.
    # Turn it into an integer and make it 1 if it was nil.
    page = (page || 1).to_i
    dataset.paginate(page, per_page, *args)
  end
end

# Define a class method to paginate through datasets
# pagination is based on github recommendation, see
# https://developer.github.com/guides/traversing-with-pagination/
# see alternative at http://dev.librato.com/v1/pagination
class Sequel::Dataset
  def page(page, per_page=30, *args)
    # The page number comes as a string from the Sinatra controller.
    # Turn it into an integer and make it 1 if it was nil.
    page = (page || 1).to_i
    paginate(page, per_page, *args)
  end
end

# An interface to the archive catalog SQL database using Sequel
# @see http://sequel.jeremyevans.net/documentation.html Sequel RDoc
# @see http://sequel.jeremyevans.net/rdoc/files/README_rdoc.html Sequel README
# @see http://sequel.jeremyevans.net/rdoc/files/doc/code_order_rdoc.html Sequel code order
class ArchiveCatalogSQL

  APP_ENV = ENV['APP_ENV']
  APP_PATH = File.absolute_path(File.join(__FILE__,'..','..','..'))
  log_file = File.open(File.join(APP_PATH,'log','db.log'), 'w+')
  LOG = Logger.new(log_file)

  def self.log_model_info(m)
    if ['development'].include?(APP_ENV)
      LOG.info "table: #{m.table_name}, columns: #{m.columns}, pk: #{m.primary_key}"
    end
  end

  # local mysql setup with db/mysql_*.sql scripts
  # deployed oracle setup with db/oracle_*.sql scripts
  db_configs = YAML.load_file('config/database.yml')
  db_config = db_configs[APP_ENV]
  raise "Missing db_config for APP_ENV=#{APP_ENV}" if db_config.nil?

  if ['test', 'development'].include?(APP_ENV)
    require 'mysql2'
    DB = Sequel.mysql2(:host=>db_config['host'],
                      :port=>db_config['port'],
                      :user=>db_config['user'],
                      :password=>db_config['password'],
                      :database=>db_config['database'],
                      :max_connections => 10,
                      :logger => LOG)
  else
    require 'oci8'
    DB = Sequel.oracle(:host=>db_config['host'],
                       :port=>db_config['port'],
                       :user=>db_config['user'],
                       :password=>db_config['password'],
                       :database=>db_config['database'],
                       :max_connections => 10,
                       :logger => LOG)
    # TODO: opts[:privilege] for oracle???
    # http://sequel.jeremyevans.net/rdoc-adapters/classes/Sequel/Oracle/Database.html
    # http://sequel.jeremyevans.net/rdoc/files/doc/opening_databases_rdoc.html#label-oracle+
  end
  DB.extension(:pagination)
  # Ensure the connection is good on startup, raises exceptions on failure
  puts db_config
  puts "#{DB} connected: #{DB.test_connection}"

  # Create Sequel Models
  # see http://sequel.jeremyevans.net/rdoc/files/README_rdoc.html#label-Sequel+Models
  # Sequel model classes assume that the table name is an underscored plural of the class name.
  # When a model class is created, it parses the schema in the table from the database,
  # and automatically sets up accessor methods for all of the columns in the table
  # (Sequel::Model implements the active record pattern).
  # A model class wraps a dataset, and an instance of that class wraps a single record in the dataset.



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

  # debug testing code
  #binding.pry
  #exit!

  #DigitalObject.insert( :digital_object_id => 'jq937jp0017', :home_repository => 'sdr' ) == 0
  # can raise Sequel::UniqueConstraintViolation

  #d = DigitalObject.where(:home_repository=>"sdr").first
  #d = DigitalObject.first
  #d.values
  #d.digital_object_id            # get value
  #d.digital_object_id = 'abc'    # set value, but not db record
  #d.save                         # update db record

  #sdr_dataset = DigitalObject.where(:home_repository=>"sdr")
  #dpn_dataset = DigitalObject.where(:home_repository=>"dpn")
  #sdr_dataset.each {|d| puts d.digital_object_id }

  # post = Post.create(:title => 'hello world')
  # post = Post.create{|p| p.title = 'hello world'}
  # Post.where(Sequel.like(:title, /ruby/)).update(:category => 'ruby')

  # set values for multiple columns in a single method call, using mass-assignment methods.
  # 'set' updates the model's column values without saving:
  #post.set(:title=>'hey there', :updated_by=>'foo')
  # 'update' sets the model's column values and then saves the changes to the database:
  #post.update(:title => 'hey there', :updated_by=>'foo')

  # Danger, Will Robinson!  Danger!
  #DigitalObject.all.each {|d| d.delete }

end
