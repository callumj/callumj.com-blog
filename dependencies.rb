require 'bundler'
require 'yaml'
Bundler.require(:default)

require 'aws/s3'
require 'json'
require 'digest/sha1'

MongoMapper.database = 'callumj_com'

Dir[File.dirname(__FILE__) + '/classes/*.rb'].each do |file| 
  require File.dirname(__FILE__) + "/classes/" + File.basename(file, File.extname(file))
end

$GLOBAL_CONFIG = {}
if (File.exists?("#{File.dirname(__FILE__)}/local_config.yml"))
  puts "Using local config"
  config_detail = YAML::load(File.open("#{File.dirname(__FILE__)}/local_config.yml"))
  $GLOBAL_CONFIG = $GLOBAL_CONFIG.merge(config_detail)
end

$BUCKET = nil

if ($GLOBAL_CONFIG["s3"] != nil)
  puts "Connecting with S3"
  
  AWS::S3::Base.establish_connection!(
      :access_key_id     => $GLOBAL_CONFIG["s3"]["access_key"],
      :secret_access_key => $GLOBAL_CONFIG["s3"]["secret"]
  )
end

require File.dirname(__FILE__) + '/webapp.rb'