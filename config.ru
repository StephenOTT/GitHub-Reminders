ENV['RACK_ENV'] ||= 'development'
require "rubygems"
require "bundler/setup"



$LOAD_PATH << File.dirname(__FILE__) + '/lib'
require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'sinatra_auth_github'))
require File.expand_path(File.join(File.dirname(__FILE__), 'app'))

use Rack::Static, :urls => ["/css", "/img", "/js"], :root => "public"



# vim:ft=ruby


client = Qless::Client.new(:host => "some-host", :port => 7000)

Rack::Builder.new do

  map('/') { run GitHubReminders::App }
  map('/qless')          { run Qless::Server.new(client) }
end