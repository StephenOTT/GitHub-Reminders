# require 'qless'
require_relative 'mongo'
# require 'octokit'
# require 'active_support'
require 'active_support/core_ext/time/zones'
require 'time_difference'
require 'qless'
require_relative 'webhook/jobs'
# require 'pp'

module Sinatra_Helpers		

		# def self.scheduled_job_date(jid)

		# 	client = Qless::Client.new
		# 	job = client.jobs[jid]
		# 	job.scheduleddate

		# end

		# TODO Add support to mark a hook creation in MongoDB as a "public"
		# hook which can be registered by other users.  Should also support
		# private hooks which means the hook creator must manage which users
		# are allowed to register for that hook.
		def self.create_gh_hook(userid, fullNameRepo, githubAPIObject)
			fullNameRepo = fullNameRepo.downcase
			# TODO after the hook is created, use the hook ID as a UUID to 
			# ensure that if someone deletes the hook in the future and 
			# then readds it, the old users with the hook will not be supported.
			repoExistsYN = self.repository_exists_in_gh?(fullNameRepo, githubAPIObject)
			if repoExistsYN == false
				return {:type => :failure, :text => "Sorry cannot create a webhook, #{fullNameRepo} does not exists"}
			end

			hookExistsGHYN = self.reminder_hook_exists_in_gh?(fullNameRepo, githubAPIObject)
			# Checks if the authenticated user has access to see the hooks in the repo.
			# If they cannot see the hooks then they would not be able to create a hook.
			if hookExistsGHYN[0] == false and hookExistsGHYN[1][:type] == :norepo
				return hookExistsGHYN[1]
			end

			hookExistsMongoYN = self.reminder_hook_exists_in_mongo?(userid, fullNameRepo)
			
			if hookExistsGHYN[0] == true
				if hookExistsMongoYN == true
					return {:type => :failure, :text => "Hook already exists in the repo: #{fullNameRepo}. No need to create another hook"}
				elsif hookExistsMongoYN == false
					# TODO rework this method call for proper handling of a message 
					# back to the user to indicate that the hook was registered 
					# from a already existing hook in GH
					return self.register_hook(userid, fullNameRepo, hookExistsGHYN[1])
				end
					
			elsif hookExistsGHYN[0] == false			
				begin
					registered_hook = githubAPIObject.create_hook(
																fullNameRepo,	'web',
																{
																	:url => 'http://www.github-reminders.com/webhook',
																	:content_type => 'json'
																},
																{
																	:events => ['issue_comment'],
																	:active => true
																})

				rescue StandardError => e
					message = e.errors.map!{|error| error[:message]}
					return {:type => :failure, :text => message}
				end

				# TODO rework this method call for proper handling of a message 
				# back to the user to indicate that the hook was registered in mongo
				return self.register_hook(userid, fullNameRepo, registered_hook.attrs[:id])

			end
		end

		# Creates a new registered hook record in mongodb for the specific user.
		def self.register_hook(userid, fullNameRepo, hookid)
			fullNameRepo = fullNameRepo.downcase
			# TODO add check to see if a record already exists in mongodb
			begin
				registered_hook_info = {
					:hookid => hookid,
					:repo => fullNameRepo.downcase,
					:active => true,
					:public => true,
					:created_at => Time.now.utc,
					:updated_at => Time.now.utc
				}
				self.find_and_modify_document(:query => {"userid" => userid},
											  :update => {"$push" => {"registered_hooks" => registered_hook_info }}
											)
				return {:type => :success, :text=>"WebHook successfully created"}
			rescue
				return {:type => :failure, :text=>"Something went wrong when we tried to register you hook"}
			end
		end

		# checks if the remidner hook already exsists for a specific repo
		# should error handle if the user does not have permission to 
		# read hooks on the repo
		def self.reminder_hook_exists_in_gh?(repo, githubAPIObject)
			repo = repo.downcase
			repoExistsYN = self.repository_exists_in_gh?(repo, githubAPIObject)
			if repoExistsYN == true
				# TODO add error message handling for github api call
				# TODO clean up poor method design
				begin
					hooks = githubAPIObject.hooks(repo)
					if hooks == nil
						hook = []
					end
				rescue
					return [false, {:type => :norepo, :text => "You do not have access to check for hooks in #{repo}"}]
				end	

				hooks.each do |h|
					if h.attrs[:config][:url] == "http://www.github-reminders.com/webhook"
						return [true, h.attrs[:id]]
						break
					else 
						[false, {:type => :failure, :text => "No hook exists"}]
					end
				end
				return [false, {:type => :failure, :text => "No hook exists"}]

			elsif repoExistsYN == false
				return [false, {:type => :failure, :text => "Repo does not exist"}]
			end
					
		end


		# Checks mongoDB for registered hooks for the user.
		def self.reminder_hook_exists_in_mongo?(userid, repo)
			repo = repo.downcase
			hooks = self.aggregate([
									{ "$match" => {userid: userid}},
									{ "$unwind" => "$registered_hooks"},
									# { "$project" => {"registered_hooks.repo" => {"$toLower"=>"$registered_hooks.repo"}}},
									{ "$match" => {"registered_hooks.repo" => repo}}
									]).count

			if hooks == 1
				return true
			elsif hooks == 0
				return false
			elsif hooks > 1
				# TODO add logic on app.rb side to account for the error message response.
				return "Something went wrong...duplicate registered hook records have been found...."		
			end
		end

		# Removes the webhook from MongoDB and GitHub
		def self.remove_webhook(userid, repo, githubAPIObject)
			repo = repo.downcase
			ghRemoval = remove_reminder_hook_from_gh(repo, githubAPIObject)
			mongoRemoval = remove_reminder_hook_from_mongo(userid, repo)

			return ghRemoval, mongoRemoval

		end


		# Deletes the reminder hook from a repo.  Only deletes the hook 
		def self.remove_reminder_hook_from_gh(repo, githubAPIObject)
			repo = repo.downcase
			hookExistsYN = self.reminder_hook_exists_in_gh?(repo, githubAPIObject)

			if hookExistsYN[0] == true
				begin
					# TODO add error message handling for github api call
					githubAPIObject.remove_hook(repo, hookExistsYN[1])
					return {:type => :success, :text =>"Hook was successfully removed from GitHub"}
				rescue
					# TODO add better error support
					return {:type => :failure, :text =>"Something when wrong when we tried to remove the hook from GitHub"}
				end
			elsif hookExistsYN[0] == false
				return {:type => :failure, :text =>"Cannot remove the hook because no Reminder hook exists on GitHub"}
			end
		end

		# Removes the registered hook in mongoDB for the specific user 
		def self.remove_reminder_hook_from_mongo(userid, repo)
			repo = repo.downcase
		# TODO add better return string support for type of text indcator hash
			hookExistsMongoYN = self.reminder_hook_exists_in_mongo?(userid, repo)

			if hookExistsMongoYN == true
				begin
					self.find_and_modify_document(:query => { "userid" => userid},
													:update => {"$pull" => {'registered_hooks' => {'repo'=>repo}}}
												)
					return {:type => :success, :text =>"WebHook has been removed from the Reminder Database"}
				rescue
					return {:type => :failure, :text =>"something went wrong when we tried to remove the webhook from the database"}
				end
			elsif hookExistsMongoYN == false
				return {:type => :failure, :text =>"We could not remove the webhook from the database because the webhook could not be found in the database"}
			else
				return {:type => :failure, :text =>hookExistsMongoYN}
			end	
		end

		# Lists the hooks that are registered by the user
		# These are the hooks created by the app.
		def self.registered_hooks_for_user(userid)
			repos = self.aggregate([
									{ "$match" => {userid: userid}},
									{ "$unwind" => "$registered_hooks"},
									# { "$match" => {"repos.repo" => repo}}
									])
			if repos == nil 
				return [{}]
			else
				return repos
			end
		end

		# Lists public hooks accross all users
		def self.registered_hooks_public_all_users
			publicHooks = self.aggregate([
									# { "$match" => {userid: userid}},
									{ "$unwind" => "$registered_hooks"},
									{ "$match" => {"registered_hooks.public" => true}}
									])
			if publicHooks == nil 
				return [{}]
			else
				return publicHooks
			end

		end

		# Determines if the hook is avaliable to be used for registering
		# Has a filter to only provide public repos in its search
		def self.hook_avaliable_for_repo_register?(repo)
			repo = repo.downcase
			hookAvaliable = self.aggregate([
									# { "$match" => {userid: userid}},
									{ "$unwind" => "$registered_hooks"},
									# { "$project" => {"registered_hooks.repo" => {"$toLower"=>"$registered_hooks.repo"}, "registered_hooks.public" => 1}},
									{ "$match" => {"registered_hooks.public" => true, "registered_hooks.repo" => repo}}
									]).count
			if hookAvaliable == 1
				return true
			elsif hookAvaliable == 0
				return false
			elsif hookAvaliable > 1
				# TODO add logic on app.rb side to account for the error message response.
				return "Something went wrong...duplicate registered hook records have been found...."		
			end

		end



		# Creates a new record/profile for the user in MongoDB
		def self.create_user(userid, attributes = {})
			self.mongo_connection
			
			userExists = self.user_exists?(userid)

			if userExists == false

				username = attributes[:username]
				name = attributes[:fullname]
				email = attributes[:email]
				timezone = attributes[:timezone]
				repos = []
				hooks = []

				userData = {
							:userid => userid,
							:username => username,
							:name => name,
							:timezone => timezone,
							:email => email,
							:created_at => Time.now.utc,
							:updated_at => Time.now.utc,
							:registered_repos => repos,
							:registered_hooks => hooks
							}
					

				self.add_mongo_data(userData)

				return {:type => :success, :text =>"User successfully Created."}
			elsif userExists == true
				return {:type => :failure, :text =>"Cannot create user, because the user already exists."}
			end
		end

		# Checks MongoDB to see if the user has a record/profile based on the userid
		def self.user_exists?(userid)
			users = self.aggregate([
									{ "$match" => {userid: userid}}
									]).count
			if users >= 1
				return true
			elsif users == 0 or users == nil
				return false
			elsif users > 1
				return "Something went wrong... duplicate users have found in our records..."
			end
		end


		# Checks MongoDB to see if the user has a record/profile based on the userid
		def self.get_user_profile(userid)
			userProfile = self.aggregate([
									{ "$match" => {userid: userid}},
									{ "$project" => {_id:0, userid: 1, email:1, name:1, timezone:1, username:1}}
									])
			
			profileCount = userProfile.count
			
			if profileCount == 1
				return userProfile[0]
			elsif profileCount > 1
				return "Oh oh, something went wrong. Multiple user counts were found that match your user ID."
			elsif profileCount == 0
				return "We could not find a user profile that matches your User ID"
			end
		end



		# Updates the user profile in MongoDB (Name, Email, Timezone)
		def self.update_user_profile(userid, attributes = {})
			name 	= attributes[:name]
			timezone 	= attributes[:timezone]
			email 		= attributes[:email]
			
			userData = {:name => name,
						:timezone => timezone,
						:email => email,
						:updated_at => Time.now.utc
						}
			begin
				self.find_and_modify_document(:query => {"userid" => userid},
												:update => {"$set" => userData}
												)
				return {:type => :success, :text =>"User Profile successfully Updated."}
			rescue
				return {:type => :failure, :text =>"Something went wrong. We cannot update your user profile."}
			end
		end

		# uses the GitHub API to get the list of authenticated emails attached to 
		# the github profile these are the email addreses that are avaliable 
		# to the user to send reminders to.
		def self.get_authenticated_github_emails(githubAPIObject)
			emails = githubAPIObject.emails
			verifiedEmails = []

			emails.each do |e|
				if e.attrs[:verified] == true
					verifiedEmails << e.attrs[:email]
				end
			end

			return verifiedEmails
		end

		# returns true if there are 1 or more verified emails, returns false 
		# if there are 0 verified emails.  Method is supposed to work with 
		# the get_authenticated_github_emails emthod
		def self.verified_emails_exist?(verifiedEmails)
			if verifiedEmails.count == 0 
				return false
			elsif verifiedEmails.count >= 1
				return true
			end
		end

		# Produces the list of timezones to be selected by the user to indicate 
		# what timezone they live in/posted the github comment from.
		# Uses ActiceSupport::TimeZone.all to return list of timezones.
		# Generates a Array of arrays. The inner array connections two strings.
		# String 1 contains the Human readable name representing the timezone.
		# String 2 contrains the timezone offset number.
		# If False is provided as a argument for the fullname argument variable,
		# the timezone offset number (formatted offset) will 
		# solely return as a array of strings
		def self.avalaible_timezones(fullname = true)
			timezones = ActiveSupport::TimeZone.all.map do |x| 
				if fullname == true
					[x.name, x.formatted_offset]
				elsif fullname == false
					"#{x.name} #{x.formatted_offset}"
				end	
			end
			timezones.uniq
			# ActiveSupport::TimeZone::UTC_OFFSET_WITH_ COLON
		end

		# Calculates the number of seconds between Issue Comments Created_At time
		# and the Reminder Time.  Takes into account the users Timezone, and the
		# GitHub UTC time.
		def self.calculate_seconds_between_commentTime_and_reminderTime(commentCreatedDate, scheduledDate)
			TimeDifference.between(commentCreatedDate, scheduledDate).in_seconds
		end

		# Lists the repos that have been registered.
		# Registration of a repo, may not inlvove the creation of the hook.
		# Hook may have already been created by another user.
		def self.registered_repos_for_user(userid)
			repos = self.aggregate([
									{ "$match" => {userid: userid}},
									{ "$unwind" => "$registered_repos"},
									# { "$match" => {"repos.repo" => repo}}
									])
			if repos == nil 
				return [{}]
			else
				return repos
			end
		end

		# Registers a repo for a specific user
		def self.register_repo_for_user(userid, repoAttributes = {})
			repoFullName = repoAttributes[:fullreponame].downcase # example: StephenOTT/Test1
			
			hookAvalaibleYN = self.hook_avaliable_for_repo_register?(repoFullName)

			if hookAvalaibleYN == false
				return {:type => :failure, :text =>"The Repository cannot be registered because either you do not have access to that GitHub Reminder hook for that repository or no Hook exists"}
			end

			registeredRepoInfo = {:repo => repoFullName,
								  :created_at => Time.now.utc,
								  :updated_at => Time.now.utc,								  
								  :active => true
								}

			repoRegistered = self.repo_registered?(userid, repoFullName)

			if repoRegistered == false				
				self.find_and_modify_document(:query => {"userid" => userid},
											  :update => {"$push" => {"registered_repos" => registeredRepoInfo }}
											)
				return {:type => :success, :text =>"Repo has been successfully registered"}

			elsif repoRegistered == true
				return {:type => :failure, :text => "Repo is already registered"}
			end
		end

		# Returns true if the repo is already registered under the specific users
		def self.repo_registered?(userid, repo)
			repo = repo.downcase
			repos = self.aggregate([
									{ "$match" => {userid: userid}},
									{ "$unwind" => "$registered_repos"},
									# { "$project" => {"registered_repos.repo" => {"$toLower"=>"$registered_repos.repo"}}},
									{ "$match" => {"registered_repos.repo" => repo}}
									]).count
									# ])
			if repos == 1
				return true
			elsif repos == 0
				return false
			elsif repos > 1
				# TODO add logic on app.rb side to account for the error message response.
				return "Something went wrong...duplicate registered repository records have been found...."		
			end
		end

		# Unregisters a user from a created hook. Does not delete the hook
		# as the hook may be being used by other users
		def self.un_register_repo_for_user(userid, repo)
			repo = repo.downcase
			repoRegistered = self.repo_registered?(userid, repo)

			if repoRegistered == true
				begin
					self.find_and_modify_document(:query => { "userid" => userid},
												:update => {"$pull" => {'registered_repos' => {'repo'=>repo}}}
												)
					return {:type => :success, :text => "repo has been removed"}
				rescue
					return {:type => :failure, :text => "something went wrong when we tried to remove the repo"}
				end
			elsif repoRegistered == false
				return {:type => :failure, :text => "We cannot unregister the repo, because you have not registred it."}
			end
					
		end

		# sets the user timezone in MongoDB
		def self.set_user_timezone(userid, timezone)
			self.find_and_modify_document(:query => {"userid" => userid},
										  :update => {"$set" => {"timezone" => timezone.to_s}}
											)
		end

		# Checks Github.com is the repo exists
		def self.repository_exists_in_gh?(repo, githubAPIObject)
			repo = repo.downcase
			begin
				repoExists = githubAPIObject.repository?(repo)
				if repoExists == false
					return false
				else
					return true
				end
			rescue StandardError => e
				message = e.errors.map!{|error| error[:message]}
				return {:type => :failure, :text => message}
			end
		end

		def self.mongo_connection(clearCollections = false)
			Mongo_Connection.mongo_Connect("localhost", 27017, ENV['MONGO_DB_NAME'], ENV['MONGO_DB_COLL_NAME'])

			if clearCollections == true
			Mongo_Connection.clear_mongo_collections
			end
		end

		# TODO find a better way to keep a constant DB Connection.  Likely add it to the Main App.
		# TODO move the mongo query info into the mogo.rb file
		def self.add_mongo_data(data)
			Sinatra_Helpers.mongo_connection
			Mongo_Connection.addIntoMongo(data)
		end

		def self.find_and_modify_document(options)
			Sinatra_Helpers.mongo_connection
			Mongo_Connection.find_and_modify_document(options)
		end

		def self.aggregate(input)
			Sinatra_Helpers.mongo_connection
			Mongo_Connection.aggregate(input)
		end


		def self.create_qless_job

			client = Qless::Client.new(:url => ENV["REDIS_URL"])
			queue = client.queues['testing']
			queue.put(SendEmail, {:hello => 'howdy'})

		end

		def self.run_qless_job(jid)

			client = Qless::Client.new(:url => ENV["REDIS_URL"])
			job = client.jobs[jid]
			job.data
		end




end

# Debug Code
# Sinatra_Helpers.mongo_connection
# Sinatra_Helpers.add_mongo_data({:date=>"123"})
# puts Sinatra_Helpers.registered_hooks_public_all_users
# puts Sinatra_Helpers.get_user_profile(1994838)
# puts Sinatra_Helpers.user_exists?(1994838)
# Sinatra_Helpers.set_user_timezone(1994838)
# puts Sinatra_Helpers.registered_hooks_for_user(1994838)
# puts Sinatra_Helpers.registered_repos_for_user(1994838)
# Sinatra_Helpers.register_repo_for_user(1994838, {:fullreponame => "stephenott/test2"})
# puts Sinatra_Helpers.repo_registered?(1994838, "stephenott/test1")
# puts Sinatra_Helpers.un_register_repo_for_user(1994838, "stephenott/Test1")
# pp Sinatra_Helpers.avalaible_timezones(false)
# pp Sinatra_Helpers.avalaible_timezones(true)
# puts Sinatra_Helpers.calculate_seconds_between_commentTime_and_reminderTime(Time.now.utc, Time.now.utc + 5.minutes)
# puts Sinatra_Helpers.hook_avaliable_for_repo_register?("StephenOTT/test1")