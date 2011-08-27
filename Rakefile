task :default => [:check_admin]

require File.dirname(__FILE__) + "/dependencies.rb"

task :check_admin do
  admin_user = User.where(:user_name => 'admin').first
  task :create_admin if admin_user == nil
end

task :create_admin do
  puts "Creating admin user"
  admin_user = User.where(:user_name => 'admin').first
  admin_user.delete unless admin_user == nil
  
  admin_user = User.new(:user_name => 'admin', :password => 'admin', :display_name => "Admin user")
  admin_user.save
end