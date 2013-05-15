A Ruby class to crawl a website using Nokogiri, MongoDB database, and MongoMapper ORM

Usage:

1. read [blog post](http://ericlondon.com/posts/249-a-ruby-class-to-crawl-a-website-using-nokogiri-mongodb-database-and-mongomapper-orm)
2. setup.readme
3. usage.rb:

```ruby
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
```
