
# include crawler class
require './ng_crawl.rb'

# instantiate crawler class object
ngc = NG_Crawl.new 'http://example.com'

# recursively crawl unprocessed URLs
ngc.crawl

# output all scanned URLs
puts ngc.all_urls

# output all external URLs
puts ngc.all_urls_external
