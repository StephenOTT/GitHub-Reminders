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