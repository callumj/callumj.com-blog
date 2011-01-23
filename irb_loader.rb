require 'rubygems'
require 'libxml'
require 'RedCloth'
require 'mongo_mapper'

MongoMapper.database = 'callumj_com'

require File.dirname(__FILE__) + '/keyman.rb'
require File.dirname(__FILE__) + '/classes/Post.rb'
