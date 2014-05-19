# require 'qless'
require_relative 'mongo'
# require 'octokit'
# require 'active_support'
require 'active_support/core_ext/time/zones'
require 'time_difference'

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
		def self.create_gh_hook(fullNameRepo, githubAPIObject)
			# TODO after the hook is created, use the hook ID as a UUID to 
			# ensure that if someone deletes the hook in the future and 
			# then readds it, the old users with the hook will not be supported.

			begin
				githubAPIObject.create_hook(
					fullNameRepo,	'web',
					{
						:url => 'http://www.GitHub-Reminders.com/webhook',
						:content_type => 'json'
					},
					{
						:events => ['issue_comment'],
						:active => true
					})
				return {:type => :success, :text=>["WebHook successfully created"]}

				rescue StandardError => e
					message = e.errors.map!{|error| error[:message]}
					return {:type => :failure, :text => message}
			end
		end

		# checks if the remidner hook already exsists for a specific repo
		# should error handle if the user does not have permission to 
		# read hooks on the repo
		def self.reminder_hook_exists?(repo, githubAPIObject)
			hooks = githubAPIObject.hooks(repo) || []
			
			hooks.each do |x|
				if x.attrs["url"] == "http://www.GitHub-Reminders.com/webhook"
					return true
					break
				else 
					false
				end
			end

		end

		# Deletes the reminder hook from a repo.  Only deletes the hook 
		# if it already exists.  Should be calling the 'reminder_hook_exists?' 
		# method to determine if the hook exsists and can be deleted.
		def self.remove_reminder_hook(repo, hookID, githubAPIObject)
			begin
				githubAPIObject.remove_hook(repo, hookID)
				return "Hook was successfully removed"
			rescue
				# TODO add better error support
				return "Something when wrong when we tried to remove the hook"
			end
		end

		# Determine the hook ID of the Remidner hook
		def self.reminder_hook_id(repo)
			hooks = githubAPIObject.hooks(repo) || []
			
			hooks.each do |x|
				if x.attrs["url"] == "http://www.GitHub-Reminders.com/webhook"
					return x.attrs["id"]
					break
				else 
					return "No GitHub-Reminder hook found"
				end
			end
		end

		# Creates a new record/profile for the user in MongoDB
		def self.create_user(userid, attributes = {})
			self.mongo_connection

			userID = attributes[:userid]
			
			userExists = self.user_exists?(userid)

			if userExists == false

				username 	= attributes[:username]
				firstName 	= attributes[:firstname] || nil
				lastName 	= attributes[:lastname] || nil
				repos 		= []

				userData = { :username => username,
							 :userid => userID,
							 :firstname => firstName,
							 :lastname => lastName,
							 :created_at => Time.now.utc,
							 :updated_at => Time.now.utc,
							 :repos => repos
							}

				self.add_mongo_data(userData)

				return "User successfully Created."
			elsif userExists == true
				return "Cannot create user, because the user already exists."
			end
		end

		# Checks MongoDB to see if the user has a record/profile based on the userid
		def self.user_exists?(userid)
			users = self.aggregate([
									{ "$match" => {userid: userid}}
									])
			if users.count >= 1
				return true
			elsif users.count == 0
				return false
			end
		end

		# Updates the user profile in MongoDB (Name, Email, Timezone)
		def self.update_user_profile(userID, attributes = {})
			firstName 	= attributes[:firstname]
			lastName 	= attributes[:lastname]
			timezone 	= attributes[:timezone] || nil
			
			userData = { :firstname => firstName,
						 :lastname => lastName,
						 :updated_at => Time.now.utc
						}

			self.find_and_modify_document(:query => {"userid" => userID},
							  				:update => {"$set" => userData}
											)
		end

		# uses the GitHub API to get the list of authenticated emails attached to 
		# the github profile these are the email addreses that are avaliable 
		# to the user to send reminders to.
		def self.get_authenticated_github_emails(githubAPIObject)
			emails = githubAPIObject.emails
			verifiedEmails = []

			emails.each do |e|
				if e.attrs["verified"] == true
					verifiedEmails << e.attrs["email"]
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
			elsif verifiedEmails >= 1
				return true
			end
		end

		# Produces the list of timezones to be selected by the user to indicate 
		# what timezone they live in/posted the github comment from.
		# Uses ActiceSupport::TimeZone.all to return list of timezones.
		def self.avalaible_timezones
			ActiveSupport::TimeZone.all
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
		def self.registered_repos_for_user(userID)
			repos = self.aggregate([
									{ "$match" => {userid: userid}},
									{ "$unwind" => "$repos"},
									# { "$match" => {"repos.repo" => repo}}
									])
			if repos == nil 
				return []
			end

		end

		# Registers a repo for a specific user
		def self.register_repo_for_user(userid, repoAttributes = {})
			repoFullName = repoAttributes[:fullreponame] # example: StephenOTT/Test1
			created_at = Time.now.utc
			active = true

			registeredRepoInfo = {:repo => repoFullName,
								  :created_at => created_at,
								  :active => active
								}

			repoRegistered = self.repo_registered?(userid, repoFullName)

			if repoRegistered == false				
				self.find_and_modify_document(:query => {"userid" => userid},
											  :update => {"$push" => {"repos" => registeredRepoInfo }}
											)
				return "Repo has been successfully registered"

			elsif repoRegistered == true
				return "Repo is already registered"
			end
		end

		# Returns true if the repo is already registered under the specific users
		def self.repo_registered?(userid, repo)
			# TODO future rebuild as a non-aggregation call.  Will look into using Find()
			repos = self.aggregate([
									{ "$match" => {userid: userid}},
									{ "$unwind" => "$repos"},
									{ "$match" => {"repos.repo" => repo}}
									]).count
			if repos >= 1
				return true
			elsif repos == 0
				return false
			end
		end

		# Unregisters a user from a created hook. Does not delete the hook
		# as the hook may be being used by other users
		def self.un_register_repo_for_user(userid, repo)
			begin
				self.find_and_modify_document(:query => { "userid" => userid},
												:update => {"$pull" => {'repos' => {'repo'=>repo}}}
											)
				return "repo has been removed"
			rescue
				return "something went wrong when we tried to remove the repo"
			end
		end

		# sets the user timezone in MongoDB
		def self.set_user_timezone(userID, timezone)
			self.find_and_modify_document(:query => {"userid" => userID},
										  :update => {"$set" => {"timezone" => timezone.to_s}}
											)
		end


		# def self.download_time_tracking_data(user, repo, githubObject, githubAuthInfo)
		#   userRepo = "#{user}/#{repo}" 
		#   Time_Tracking_Controller.controller(userRepo, githubObject, true, githubAuthInfo)
		# end

		# def self.issues(user, repo, githubAuthInfo)
		#   Issues_Processor.analyze_issues(user, repo, githubAuthInfo)
		# end


		def self.mongo_connection(clearCollections = false)
			Mongo_Connection.mongo_Connect("localhost", 27017, "GitHub-Reminders", "Users")

			if clearCollections == true
			Mongo_Connection.clear_mongo_collections
			end
		end

		def self.add_mongo_data(data)
			Mongo_Connection.addIntoMongo(data)
		end

		def self.find_and_modify_document(options)
			Mongo_Connection.find_and_modify_document(options)
		end

		def self.aggregate(input)
			Mongo_Connection.aggregate(input)
		end
end

# Debug Code
# Sinatra_Helpers.mongo_connection
# puts Sinatra_Helpers.user_exists?(1994838)
# Sinatra_Helpers.set_user_timezone(1994838)
# Sinatra_Helpers.register_repo_for_user(1994838, {:fullreponame => "stephenott/test1"})
# puts Sinatra_Helpers.repo_registered?(1994838, "stephenott/test1")
# puts Sinatra_Helpers.un_register_repo_for_user(1994838, "stephenott/test1")
# puts Sinatra_Helpers.avalaible_timezones
# puts Sinatra_Helpers.calculate_seconds_between_commentTime_and_reminderTime(Time.now.utc, Time.now.utc + 5.minutes)

