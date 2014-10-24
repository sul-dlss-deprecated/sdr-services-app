
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
    require 'sequel'

    # connect to an in-memory database
    configure :development do
      register Sinatra::Reloader
      DB = Sequel.sqlite

      # create an items table
      DB.create_table :items do
        primary_key :id
        String :name
        Float :price
      end
      # create a dataset from the items table
      items = DB[:items]
      # populate the table
      items.insert(:name => 'abc', :price => rand * 100)
      items.insert(:name => 'def', :price => rand * 100)
      items.insert(:name => 'ghi', :price => rand * 100)
      # print out the number of records
      puts "Item count: #{items.count}"
      # print out the average price
      puts "The average price is: #{items.avg(:price)}"
    end

  end

end

