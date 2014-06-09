require_relative 'sinatra_helpers'

module GitHubReminders
	class App < Sinatra::Base

		enable :sessions
		use Rack::Flash, :sweep => true

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
				# @username = github_user.login
				# @gravatar_id = github_user.gravatar_id
				# @fullName = github_user.name
				# @userID = github_user.id

				userExistsYN = Sinatra_Helpers.user_exists?(get_auth_info[:userID])

				if userExistsYN == false
					redirect '/signup'
				end

				@registeredHookList = Sinatra_Helpers.registered_hooks_for_user(get_auth_info[:userID])
				@registeredRepoList = Sinatra_Helpers.registered_repos_for_user(get_auth_info[:userID])
				@publicHookList = Sinatra_Helpers.registered_hooks_public_all_users
			else
				flash[:warning] = ["Please login to continue"]
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
				flash[:warning] = ["You must be logged in"]
				erb :unauthenticated
			end     
		end

		# Displays the current authenticated user's profile information
		get '/profile' do
			if authenticated? == true

				userExistsYN = Sinatra_Helpers.user_exists?(github_user.id)
				if userExistsYN == false
					redirect '/'
				end

				userProfile = Sinatra_Helpers.get_user_profile(github_user.id)

				@fullname = userProfile["name"]
				@email = userProfile["email"]
				@timezone = userProfile["timezone"]
				@userid = userProfile["userid"]
				@username = userProfile["username"]

				@timezonesList = Sinatra_Helpers.avalaible_timezones
				@githubEmails = Sinatra_Helpers.get_authenticated_github_emails(github_api)
				@githubEmailsVerfiedExistsYN = Sinatra_Helpers.verified_emails_exist?(@githubEmails)

				erb :user_profile
			else
				flash[:warning] = ["You must be logged in"]
				erb :unauthenticated
			end    
		end


		# Creates a new user in the MongoDB.  Has full logic for 
		# data validations and ensures that there is not already 
		# the same user in the DB
		post '/createuser' do

			post = params[:post]

			if authenticated? == true

				formErrors = []

				userExistsYN = Sinatra_Helpers.user_exists?(github_user.id)

				if userExistsYN == true
					redirect '/'					
				end

				# Server Side validation of the Name, Email, and Timezone data fields
				if post["fullname"].size > 255
					formErrors << "your name is too long.  Must be less than 255 characters"
				end

				if post["fullname"].size == 0
					formErrors << "You must provide a name"
				end

				@githubEmails = Sinatra_Helpers.get_authenticated_github_emails(github_api)
				@githubEmailsVerfiedExistsYN = Sinatra_Helpers.verified_emails_exist?(@githubEmails)
				
				if @githubEmailsVerfiedExistsYN == false 
					formErrors << "You do not have any verified github email addresses.  You must have a GitHub Verified email to continue"
				end

				if @githubEmails.include?(post["email"]) == false
					formErrors << "Invalid Email. You must be a GitHub.com validated email"
				end

				@timezonesList = Sinatra_Helpers.avalaible_timezones
				@timezonesListLongName = Sinatra_Helpers.avalaible_timezones(false)

				if @timezonesListLongName.include?(post["timezone"]) == false
					formErrors << "invalid timezone."
				end
				flash[:danger] = formErrors
				# Adds the data to Mongodb.  
				# Success and Error will be returned with a String message
				if formErrors.length == 0 
					createdUser = Sinatra_Helpers.create_user( get_auth_info[:userID], 
												{:username => get_auth_info[:username],
												 :fullname => post["fullname"],
												 :timezone => post["timezone"],
												 :email => post["email"]
												 })

	 				if createdUser[:type] == :success
						flash[:success] = [createdUser[:text]]
						redirect '/'
					elsif createdUser[:type] == :failure
						flash[:warning] = [createdUser[:text]]
					end
				end
				
			erb :signup
			else
				flash[:warning] = ["You must be logged in"]
				erb :unauthenticated
			end  
		end

		# Updates a new user in the MongoDB.  Has full logic for 
		# data validations and ensures that there is not already 
		# the same user in the DB
		post '/updateuser' do

			post = params[:post]

			if authenticated? == true

				formErrors = []

				userExistsYN = Sinatra_Helpers.user_exists?(github_user.id)

				if userExistsYN == false
					redirect '/'					
				end

				# Server Side validation of the Name, Email, and Timezone data fields
				if post["fullname"].size > 255
					formErrors << "your name is too long.  Must be less than 255 characters"
				end

				if post["fullname"].size == 0
					formErrors << "You must provide a name"
				end

				@githubEmails = Sinatra_Helpers.get_authenticated_github_emails(github_api)
				@githubEmailsVerfiedExistsYN = Sinatra_Helpers.verified_emails_exist?(@githubEmails)
				
				if @githubEmailsVerfiedExistsYN == false 
					formErrors << "You do not have any verified github email addresses.  You must have a GitHub Verified email to continue"
				end

				if @githubEmails.include?(post["email"]) == false
					formErrors << "Invalid Email. You must be a GitHub.com validated email"
				end

				@timezonesList = Sinatra_Helpers.avalaible_timezones
				@timezonesListLongName = Sinatra_Helpers.avalaible_timezones(false)

				if @timezonesListLongName.include?(post["timezone"]) == false
					formErrors << "invalid timezone."
				end
				flash[:danger] = formErrors
				# Adds the data to Mongodb.  
				# Success and Error will be returned with a String message
				if formErrors.length == 0 
					updatedUser = Sinatra_Helpers.update_user_profile(get_auth_info[:userID], 
																{:name => post["fullname"],
																 :timezone => post["timezone"],
																 :email => post["email"]
																 })

	 				if updatedUser[:type] == :success
						flash[:success] = [updatedUser[:text]]
						redirect '/profile'
					elsif updatedUser[:type] == :failure
						flash[:warning] = [updatedUser[:text]]
					end
				end
				
			erb :user_profile
			else
				flash[:warning] = ["You must be logged in"]
				erb :unauthenticated
			end  
		end


		# registers a repo for a specific user
		get '/registerrepo/:username/:repository' do
			# post = params[:post]
			if authenticated? == true
				fullRepoName = "#{params[:username]}/#{params[:repository]}"
				
				registeredRepo = Sinatra_Helpers.register_repo_for_user(get_auth_info[:userID], {:fullreponame => fullRepoName})
				if registeredRepo[:type] == :success
					flash[:success] = [registeredRepo[:text]]
				elsif registeredRepo[:type] == :failure
					flash[:warning] = [registeredRepo[:text]]
				end

				redirect '/'

			# erb :index
			else
				flash[:warning] = ["You must be logged in"]
				erb :unauthenticated
			end 
		end

		# unregister a repo for a specific user
		get '/unregisterrepo/:username/:repository' do
			# post = params[:post]
			if authenticated? == true
				fullRepoName = "#{params[:username]}/#{params[:repository]}"
				
				unregisteredRepo = Sinatra_Helpers.un_register_repo_for_user(get_auth_info[:userID], fullRepoName)

				if unregisteredRepo[:type] == :success
					flash[:success] = [unregisteredRepo[:text]]
				elsif unregisteredRepo[:type] == :failure
					flash[:warning] = [unregisteredRepo[:text]]
				end

				redirect '/'
			# erb :index
			else
				flash[:warning] = ["You must be logged in"]
				erb :unauthenticated
			end 
		end

		get '/registerhook/?:username?/?:repository?' do
			# post = params[:post]
			if authenticated? == true
				fullRepoName = "#{params[:username]}/#{params[:repository]}"
				
				createdHook = Sinatra_Helpers.create_gh_hook(get_auth_info[:userID], fullRepoName, github_api)
				if createdHook[:type] == :success
					flash[:success] = [createdHook[:text]]
				elsif createdHook[:type] == :failure
					flash[:warning] = [createdHook[:text]]
				end
				redirect '/'
			# erb :index
			else
				flash[:warning] = ["You must be logged in"]
				erb :unauthenticated
			end     
		end

		# Deletes a webhook
		get '/unregisterhook/:username/:repository' do
			# post = params[:post]
			if authenticated? == true
				fullRepoName = "#{params[:username]}/#{params[:repository]}"

				ghRemoval, mongoRemoval = Sinatra_Helpers.remove_webhook(get_auth_info[:userID], fullRepoName, github_api)

				if ghRemoval[:type] == :success
					(flash[:success] ||= []) << ghRemoval[:text]
				elsif ghRemoval[:type] == :failure
					(flash[:warning] ||= []) << ghRemoval[:text]
				end
				if mongoRemoval[:type] == :success
					(flash[:success] ||= []) << mongoRemoval[:text]
				elsif mongoRemoval[:type] == :failure
					(flash[:warning] ||= []) << mongoRemoval[:text]
				end

				redirect '/'
			# erb :index
			else
				flash[:warning] = ["You must be logged in"]
				erb :unauthenticated
			end     
		end

		post '/webhook' do
			puts params[:payload].to_s

			Sinatra_Helpers.send_comment_to_qless(params[:payload].to_s)
		end


		get '/emailtest' do
			if authenticated? == true
				userProfile = Sinatra_Helpers.get_user_profile(get_auth_info[:userID])
				qlessJob = Sinatra_Helpers.create_qless_job({:username => "StephenOTT", 
													:repo => "StephenOTT/Test1", 
													:issueNumber => 123,
													:toEmail => "#{userProfile["name"]} <#{userProfile["email"]}>",
													:subject => "Test Subject 2",
													:body => "Test Body 123",
													:delay => 0})
				flash[:success] = ["Email has been send.  Qless Job ID: #{qlessJob}"]
				redirect '/'
			else
				flash[:warning] = ["You must be logged in"]
				erb :unauthenticated
			end  

		end

		get '/runjob/:jid' do
			Sinatra_Helpers.run_qless_job(params["jid"])
		end


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