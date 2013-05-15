require 'open-uri'
require 'nokogiri'

require './ng_url.rb'

class NG_Crawl

  @url_initial = nil
  @ng_url_initial = nil

  def initialize(url)

    unless url_valid? url
      puts "Initial URL is not valid.\n"
      exit
    end

    # set intial url to class instance variable
    @url_initial = url
    @ng_url_initial = url_to_object url

    # scan initial
    scan_ng_url @ng_url_initial

  end

  # method to recursively crawl unprocessed URLs
  def crawl
    while NG_URL.where(:a_hrefs_unprocessed => { :$not => { :$size => 0}}).count > 0 do
      next_unprocessed_url
    end
  end

  # method that returns an Array of all URLs
  def all_urls
    urls = NG_URL.all.collect {|n| n.url}
    urls.sort!
  end

  # method that returns an Array of all external URLs
  def all_urls_external
    ngurls = NG_URL.all(:a_hrefs_external => { :$not => { :$size => 0}})
    urls_external = []
    ngurls.each {|n| urls_external += n.a_hrefs_external }
    urls_external.uniq!.sort!
  end

  def url_valid?(url)
    (url =~ URI::regexp).nil? ? false : true
  end

  # returns NG_URL object for URL string, creates as necessary
  def url_to_object(url)

    # load existing object
    ngurl = NG_URL.last(:url => url)
    if ngurl.nil?
      uri = URI url

      ngurl = NG_URL.new
      ngurl.url = url
      ngurl.host = uri.host
      ngurl.scheme_host = "#{uri.scheme}://#{uri.host}"
      if uri.port == 3000
        ngurl.scheme_host = ngurl.scheme_host + ':3000'
      end
      ngurl.host_base = get_url_host_base uri.host
      ngurl.a_hrefs_unprocessed = []
      ngurl.a_hrefs_processed = []

      ngurl.save!
    end

    ngurl

  end

  # returns hostname without any subdomains
  def get_url_host_base(host)
    host_split = host.split '.'

    # check for hostnames without periods, like "localhost"
    if host_split.size == 1
      return host
    end

    host_split.pop(2).join('.')

  end

  def scan_ng_url(ngurl)

    # check if url has already been scanned
    unless ngurl.scanned_at.nil?
      return true
    end

    begin
      openuri = open ngurl.url
    rescue
      ngurl.error_exists = true
      ngurl.save!
      return false
    end

    ngurl.content_type = openuri.content_type
    ngurl.http_status_code = openuri.status.first
    ngurl.content_length = openuri.meta['content-length']
    ngurl.scanned_at = Time.new

    # check for text content types
    if openuri.content_type =~ /^text/

      doc = Nokogiri::HTML(openuri)
      a_hrefs = doc.css('a').collect {|a| a['href']}

      ngurl.document = doc
      ngurl.a_hrefs_unprocessed = a_hrefs

    end

    ngurl.save!

  end

  def next_unprocessed_url

    # find ng_url object with unprocessed a_hrefs
    ngurl = NG_URL.where(:a_hrefs_unprocessed => { :$not => { :$size => 0}}).sort(:created_at.asc).first

    url = ngurl.a_hrefs_unprocessed.shift

    if url.nil?
      ngurl.save!
      return
    end

    # debug
    p url

    uri = URI url

    # check for urls to ignore
    if url =~ /^#/ || url =~ /^javascript:/ || url =~ /^mailto:/
      ngurl.a_hrefs_ignored << url
      ngurl.save!
      return
    end

    # check scheme
    scheme = uri.scheme
    if !scheme.nil? && !['http', 'https'].include?(scheme)
      ngurl.a_hrefs_ignored << url
      ngurl.save!
      return
    end

    # check for urls starting with '/'
    if url =~ /^\//
      url = @ng_url_initial.scheme_host + url
    end

    # check for relative links beginning with '../'
    # todo: ensure this is working
    if url =~ /^\.\.\//
      url = fix_relative_parent_url(ngurl.url, url)
    end

    # check for relative links
    if not url =~ /^(http|https):\/\//
      parent_url = ngurl.url
      if parent_url[-1..-1] != '/'
        parent_url = parent_url[0..parent_url.rindex('/')]
      end
      url = "#{parent_url}#{url}"
    end

    # check if url is external
    if url_external? ngurl.host_base, url
      ngurl.a_hrefs_external << url
      ngurl.save!
      return
    end

    # remove trailing slash from url
    if url[-1..-1] == '/'
      url = url[0..-2]
    end

    # check if url object has not yet been created
    ngurl_count = NG_URL.where(:url => url).count
    if ngurl_count == 0
      # scan unprocessed url
      new_ngurl = url_to_object url
      scan_ng_url new_ngurl
    end

    # add url to processed list
    ngurl.a_hrefs_processed << url
    ngurl.save!

  end

  def url_external?(host_base, url)
    uri = URI url
    url_host_base = get_url_host_base(uri.host)
    not host_base == url_host_base
  end

  def fix_relative_parent_url(parent_url, url)

    if parent_url[-1..-1] != '/'
      parent_url = parent_url[0..parent_url.rindex('/')]
    end
    uri = URI parent_url
    uri_path_split = uri.path.split '/'

    url_split = url.split '../'
    url_remainder = ''
    url_split.each do |s|
      if s.empty?
        uri_path_split.pop
      else
        url_remainder = s
      end
    end

    new_url = "#{uri.scheme}://#{uri.host}"
    if uri.port == 3000
      new_url = new_url + ':3000'
    end
    new_url = "#{new_url}#{uri_path_split.join('/')}/#{url_remainder}"

  end

end
