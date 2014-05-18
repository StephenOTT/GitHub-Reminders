# require_relative '../time_analyzer/system_wide_processor'
# require 'qless'
# require_relative 'mongo'
# require 'octokit'

module Sinatra_Helpers

		# def self.get_all_repos_for_logged_user(githubAuthInfo)
		#   System_Wide_Processor.all_repos_for_logged_user(githubAuthInfo)
		# end
		

		# def self.scheduled_job_date(jid)

		# 	client = Qless::Client.new
		# 	job = client.jobs[jid]
		# 	job.scheduleddate

		# end

		# TODO Add support to mark a hook creation in MongoDB as a "public"
		# hook which can be registered by other users.  Should also support
		# private hooks which means the hook creator must manage which users
		# are allowed to register for that hook.
		def self.create_gh_hook(fullNameRepo, githubObject)
			begin
				githubObject.create_hook(
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
		def self.reminder_hook_exists?(repo)

		end

		# Deletes the reminder hook from a repo.  Only deletes the hook 
		# if it already exists.  Should be calling the 'reminder_hook_exists?' 
		# method to determine if the hook exsists and can be deleted.
		def self.delete_reminder_hook(repo)

		end

		# Creates a new record/profile for the user in MongoDB
		def self.create_user

		end

		# Checks MongoDB to see if the user has a record/profile
		def self.user_exists?

		end

		# Updates the user profile in MongoDB (Name, Email, Timezone)
		def self.update_user_profile

		end

		# uses the GitHub API to get the list of authenticated emails attached to 
		# the github profile these are the email addreses that are avaliable 
		# to the user to send reminders to.
		def self.get_authenticated_github_emails

		end

		# produces the list of timezones to be selected by the user to indicate 
		# what timezone they live in/posted the github comment from.
		def self.avalaible_timezones

		end

		# Calculates the number of seconds between Issue Comments Created_At time
		# and the Reminder Time.  Takes into account the users Timezone, and the
		# GitHub UTC time.
		def self.calculate_seconds_between_commentTime_and_reminderTime

		end

		# Lists the repos that have been registered.
		# Registration of a repo, may not inlvove the creation of the hook.
		# Hook may have already been created by another user.
		def self.registered_repos_for_user(userID)

		end

		# Unregisters a user from a created hook. Does not delete the hook
		# as the hook may be being used by other users
		def self.un_register_repo_for_user(userID, repo)

		end



		# def self.download_time_tracking_data(user, repo, githubObject, githubAuthInfo)
		#   userRepo = "#{user}/#{repo}" 
		#   Time_Tracking_Controller.controller(userRepo, githubObject, true, githubAuthInfo)
		# end

		# def self.issues(user, repo, githubAuthInfo)
		#   Issues_Processor.analyze_issues(user, repo, githubAuthInfo)
		# end


		def mongo_connection(clearCollections = true)

			Mongo_Connection.mongo_Connect("localhost", 27017, "GitHub-Analytics", "Issues-Data")

			if clearCollections == true
			Mongo_Connection.clear_mongo_collections
			end

		end

		def add_mongo_data(data)
			Mongo_Connection.addReminder(data)
		end
end