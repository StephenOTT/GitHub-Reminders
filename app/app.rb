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

				userExistsYN = Sinatra_Helpers.user_exists?(@userID)

				if userExistsYN == false
					redirect '/signup'
				end

			else
				# @dangerMessage = "Danger... Warning!  Warning"
				@warningMessage = ["Please login to continue"]
				# @infoMessage = "Info 123"
				# @successMessage = "Success"
			end
			erb :index
		end

		# /signup is a landing page with a form for the user to sign up.  
		# Server side data validation is done in the /createuser 
		# call to allow for future API use
		get '/signup' do
			if authenticated? == true

				userExistsYN = Sinatra_Helpers.user_exists?(github_user.id)

				if userExistsYN == true
					redirect '/'
				end

				@timezonesList = Sinatra_Helpers.avalaible_timezones
				@githubEmails = Sinatra_Helpers.get_authenticated_github_emails(github_api)
				@githubEmailsVerfiedExistsYN = Sinatra_Helpers.verified_emails_exist?(@githubEmails)

				erb :signup
			else
				@warningMessage = ["You must be logged in"]
				erb :unauthenticated
			end     
		end


		# Creates a new user in the MongoDB.  Has full logic for 
		# data validations and ensures that there is not already 
		# the same user in the DB
		get '/createuser' do

			post = params[:post]

			if authenticated? == true

				userExistsYN = Sinatra_Helpers.user_exists?(github_user.id)

				if userExistsYN == true
					redirect '/'					
				end
				
				# Server Side validation of the Name, Email, and Timezone data fields
				if post["fullname"].size > 255
					return "your name is too long.  Must be less than 255 characters"
				end

				@githubEmails = Sinatra_Helpers.get_authenticated_github_emails(github_api)
				@githubEmailsVerfiedExistsYN = Sinatra_Helpers.verified_emails_exist?(@githubEmails)
				
				if @githubEmailsVerfiedExistsYN == false 
					return "You do not have any verified github email addresses."
				end

				if @githubEmails.include?(post["email"]) == false
					return "Invalid Email. Must be a email validated by GitHub.com"
				end

				@timezonesList = Sinatra_Helpers.avalaible_timezones
				@timezonesListShort = Sinatra_Helpers.avalaible_timezones(false)
				# puts post["timezone"]
				if @timezonesListShort.include?(post["timezone"]) == false
					return "invalid timezone."
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