require_relative 'sinatra_helpers'

module GitHubReminders
	class App < Sinatra::Base
		enable :sessions

		set :github_options, {
			:scopes    => "user, admin:repo_hook",
			:secret    => ENV['GITHUB_CLIENT_SECRET'],
			:client_id => ENV['GITHUB_CLIENT_ID'],
		}

		register Sinatra::Auth::Github

		helpers do

			def get_auth_info
				authInfo = {:username => github_user.login, :userID => github_user.id}
			end

		end

		get '/' do
			# authenticate!
			if authenticated? == true
				@username = github_user.login
				@gravatar_id = github_user.gravatar_id
				@fullName = github_user.name
				@userID = github_user.id


			else
				# @dangerMessage = "Danger... Warning!  Warning"
				@warningMessage = ["Please login to continue"]
				# @infoMessage = "Info 123"
				# @successMessage = "Success"
			end
			erb :index
		end

		get '/repos' do
			if authenticated? == true
				erb :add_repo
			else
				@warningMessage = ["You must be logged in"]
				erb :unauthenticated
			end     
		end


		post '/addwebhook' do
			post = params[:post]
			if authenticated? == true
				fullRepoName = "#{post['username']}/#{post['repository']}"
				
				createdHook = Sinatra_Helpers.create_gh_hook(fullRepoName, github_api)
				
				if createdHook[:type] == :success
					@successMessage = createdHook[:text]
				elsif createdHook[:type] == :failure
					@warningMessage = createdHook[:text]
				end

			erb :add_repo
			else
				@warningMessage = ["You must be logged in"]
				erb :unauthenticated
			end     
		end




		# get '/download/:user/:repo' do
		#   authenticate!
		#   Sinatra_Helpers.download_time_tracking_data(params['user'], params['repo'], github_api, get_auth_info )
		#   @successMessage = "Download Complete"
		#   redirect '/timetrack'
		# end



		get '/logout' do
			logout!
			redirect '/'
		end
		get '/login' do
			authenticate!
			redirect '/'
		end
	end
end