require File.dirname(__FILE__) + "/dependencies.rb"


set :env, :production
set :server, 'thin'
disable :run

run Sinatra::Application
