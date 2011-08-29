task :default => [:check_admin]

require File.dirname(__FILE__) + "/dependencies.rb"

class BasicDownload
  include HTTParty
  format :plain
end

task :check_admin do
  admin_user = User.where(:user_name => 'admin').first
  Rake::Task["create_admin"].execute if admin_user == nil
end

task :create_admin do
  puts "Creating admin user"
  admin_user = User.where(:user_name => 'admin').first
  admin_user.delete unless admin_user == nil
  
  admin_user = User.new(:user_name => 'admin', :password => 'admin', :display_name => "Admin user")
  admin_user.save
end

task :import_posts do
  if ENV["MONGO_BIN"] == nil
    puts "No MongoDB bin path defined"
    next
  end
  
  #download from s3
  posts_file = AWS::S3::S3Object.url_for("posts.callumjcom.json", $GLOBAL_CONFIG["s3"]["buckets"]["default"])
  file = BasicDownload.get(posts_file)
  loc = "/tmp/#{Time.now.to_i}_posts.json"
  File.open(loc, 'w') {|f| f.write(file.body) }
  
  #import into mongo
  puts "#{ENV["MONGO_BIN"]}/mongoimport -d #{MongoMapper.database.name} -c posts --file #{loc}"
  `#{ENV["MONGO_BIN"]}/mongoimport -d #{MongoMapper.database.name} -c posts --file #{loc}`
end