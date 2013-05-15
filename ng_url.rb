require 'mongo_mapper'

class NG_URL
  include MongoMapper::Document

  #MongoMapper.connection = Mongo::Connection.new('localhost', 27017)
  #MongoMapper.database = "ng_crawl"
  connection Mongo::Connection.new('localhost', 27017)
  set_database_name 'ng_crawl'

  timestamps!
  key :url, String
  key :host, String
  key :host_base, String
  key :scheme_host, String
  key :error_exists, Boolean
  key :content_type, String
  key :http_status_code, String
  key :content_length, Integer
  key :document, String
  key :a_hrefs_unprocessed, Array
  key :a_hrefs_processed, Array
  key :a_hrefs_external, Array
  key :a_hrefs_ignored, Array
  key :scanned_at, Time
end
