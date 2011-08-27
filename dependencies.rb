require 'bundler'
Bundler.require(:default)

MongoMapper.database = 'callumj_com'

Dir[File.dirname(__FILE__) + '/classes/*.rb'].each do |file| 
  require File.dirname(__FILE__) + "/classes/" + File.basename(file, File.extname(file))
end

require File.dirname(__FILE__) + '/webapp.rb'