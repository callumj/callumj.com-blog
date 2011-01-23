require 'json'
require 'net/http'
s = Net::HTTP.get_response(URI.parse('http://stackoverflow.com/feeds/tag/ruby/')).body
Hash.from_xml(s).to_json