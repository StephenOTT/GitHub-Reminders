ENV['RACK_ENV'] ||= 'development'
require "rubygems"
require "bundler/setup"



$LOAD_PATH << File.dirname(__FILE__) + '/lib'
require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'sinatra_auth_github'))
require File.expand_path(File.join(File.dirname(__FILE__), 'app'))


# vim:ft=ruby


client = Qless::Client.new(:url => ENV["REDISCLOUD_URL")

Rack::Builder.new do
	use Rack::Static, :urls => ["/css", "/img", "/js"], :root => "public"

  map('/') 				 { run GitHubReminders::App }
  map('/qless')          { run Qless::Server.new(client) }
end