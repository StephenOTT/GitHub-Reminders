require 'sinatra'
require_relative './webhook/controller'


post '/webhook' do

WebHook_Controller.is_Reminder_Comment?(params[:comment][:body])



end