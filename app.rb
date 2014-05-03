
require 'octokit'
# require 'json'
require_relative 'helpers'
require 'chronic'
require 'active_support/time'
require 'rest-client'

def is_Reminder_Comment?(commentBody)
	isReminderComment = Helpers.reminder_comment?(commentBody)
end



def self.parse_time_commit(timeComment, userTimezone)
	acceptedClockEmoji = Helpers.get_Reminder_Emoji
	# acceptedNonBilliableEmoji = Helpers.get_Non_Billable_Emoji

	parsedCommentHash = { # "duration" => nil, 
							# "non_billable" => nil, 
							"work_date" => nil, 
							"time_comment" => nil, 
							# "work_date_provided" => false
						}
	parsedComment = []
	
	acceptedClockEmoji.each do |x|
		# if nonBillableTime == true
		# 	acceptedNonBilliableEmoji.each do |b|
		# 		if timeComment =~ /\A#{x}\s#{b}/
		# 			parsedComment = Helpers.parse_non_billable_time_comment(timeComment,x,b)
		# 			parsedCommentHash["non_billable"] = true
		# 			break
		# 		end
		# 	end
		# elsif nonBillableTime == false
			if timeComment =~ /\A#{x}/
				parsedComment = Helpers.parse_billable_time_comment(timeComment,x)
				# parsedCommentHash["non_billable"] = false
				break
			end
		# end
	end
	
	if parsedComment.empty? == true
		return nil
	end

	# if parsedComment[0] != nil
	# 	parsedCommentHash["duration"] = Helpers.get_duration(parsedComment[0])
	# end
	puts parsedComment[0]
	if parsedComment[0] != nil
		workDate = Helpers.get_time_work_date(parsedComment[0], userTimezone)
			if workDate != nil
				parsedCommentHash["work_date"] = workDate
				# parsedCommentHash["work_date_provided"] = true
			elsif workDate == nil
			return puts "bad date syntax"
			# 	parsedCommentHash["time_comment"] = Helpers.get_time_commit_comment(parsedComment[1])

			end
	end

	if parsedComment[1] != nil
		parsedCommentHash["time_comment"] = Helpers.get_time_commit_comment(parsedComment[1])
	end

	return parsedCommentHash
end







def gh_authenticate(username, password)
	@ghClient = Octokit::Client.new(
									:login => username.to_s, 
									:password => password.to_s, 
									:auto_paginate => true
									# :per_page => 100
									)
end

def get_gh_user_emails

	@ghClient.emails

end

def get_user_timezone

	# TODO create method for getting the stored timezone of a user from DB

end

# creates the 
def create_gh_hook(fullNameRepo)

	@ghClient.create_hook(
		fullNameRepo,
	  'web',
	  {
	    :url => 'http://something.com/webhook',
	    :content_type => 'json'
	  },
	  {
	    :events => ['issue_comment'],
	    :active => true
	  }
	)

end





def send_simple_message(deliveryTime)
	RestClient.post "https://api:key-2yv1iyo9uad8dc02tokp1-5nzb03s7u5"\
	"@api.mailgun.net/v2/sandbox7a90f2af1ae6406bbd6f4ef9cff652b3.mailgun.org/messages",
	"from" => "Mailgun Sandbox <postmaster@sandbox7a90f2af1ae6406bbd6f4ef9cff652b3.mailgun.org>",
	"to" => "Stephen Russett <stephenrussett@gmail.com>",
	"subject" => "GitHub Reminder",
	"text" => "This is a Github-Reminder",
	"o:deliverytime" => deliveryTime.rfc2822
end






def process_request(issueCommentEvent, userTimezone)

	repo = issueCommentEvent["repository"]["full_name"]
	issueURL = issueCommentEvent["issue"]["html_url"]
	issueTitle = issueCommentEvent["issue"]["title"]
	issueState = issueCommentEvent["issue"]["state"]
	comment = issueCommentEvent["comment"]["body"]
	commentURL = issueCommentEvent["comment"]["html_url"]
	commentCreated_At = issueCommentEvent["comment"]["created_at"]
	# timezoneOffset = "+05:00"
	commentUserName = issueCommentEvent["comment"]["user"]["login"]
	commentUserID = issueCommentEvent["comment"]["user"]["id"]

	puts repo
	puts issueURL
	puts issueTitle
	puts issueState
	puts comment

	Time.zone = userTimezone
	Chronic.time_class = Time.zone
	puts Chronic.parse(commentCreated_At).in_time_zone(userTimezone)
	
	# puts commentCreated_At
	puts commentURL
	puts "===="

	puts is_Reminder_Comment?(comment)
	parsedComment = parse_time_commit(comment, userTimezone)
	puts parsedComment["work_date"]
	puts parsedComment["time_comment"]
	# send_simple_message(parsedComment["work_date"])
end


#Used for Testing
rawDataValue = {
  "action" => "created",
  "issue" => {
    "url" => "https://api.github.com/repos/StephenOTT/Test1/issues/9",
    "labels_url" => "https://api.github.com/repos/StephenOTT/Test1/issues/9/labels{/name}",
    "comments_url" => "https://api.github.com/repos/StephenOTT/Test1/issues/9/comments",
    "events_url" => "https://api.github.com/repos/StephenOTT/Test1/issues/9/events",
    "html_url" => "https://github.com/StephenOTT/Test1/issues/9",
    "id" => 28309561,
    "number" => 9,
    "title" => "TimeTrack - Issues test",
    "user" => {
      "login" => "draganstudios",
      "id" => 1308229,
      "avatar_url" => "https://avatars.githubusercontent.com/u/1308229?",
      "gravatar_id" => "04dd87869c2fb76160ca46e19055296f",
      "url" => "https://api.github.com/users/draganstudios",
      "html_url" => "https://github.com/draganstudios",
      "followers_url" => "https://api.github.com/users/draganstudios/followers",
      "following_url" => "https://api.github.com/users/draganstudios/following{/other_user}",
      "gists_url" => "https://api.github.com/users/draganstudios/gists{/gist_id}",
      "starred_url" => "https://api.github.com/users/draganstudios/starred{/owner}{/repo}",
      "subscriptions_url" => "https://api.github.com/users/draganstudios/subscriptions",
      "organizations_url" => "https://api.github.com/users/draganstudios/orgs",
      "repos_url" => "https://api.github.com/users/draganstudios/repos",
      "events_url" => "https://api.github.com/users/draganstudios/events{/privacy}",
      "received_events_url" => "https://api.github.com/users/draganstudios/received_events",
      "type" => "User",
      "site_admin" => false
    },
    "labels" => [
      {
        "url" => "https://api.github.com/repos/StephenOTT/Test1/labels/Dog",
        "name" => "Dog",
        "color" => "e11d21"
      },
      {
        "url" => "https://api.github.com/repos/StephenOTT/Test1/labels/Priority%3A+High",
        "name" => "Priority: High",
        "color" => "006b75"
      }
    ],
    "state" => "open",
    "assignee" => {
      "login" => "StephenOTT",
      "id" => 1994838,
      "avatar_url" => "https://avatars.githubusercontent.com/u/1994838?",
      "gravatar_id" => "365f114d7010e905f4b47865da4d0d1e",
      "url" => "https://api.github.com/users/StephenOTT",
      "html_url" => "https://github.com/StephenOTT",
      "followers_url" => "https://api.github.com/users/StephenOTT/followers",
      "following_url" => "https://api.github.com/users/StephenOTT/following{/other_user}",
      "gists_url" => "https://api.github.com/users/StephenOTT/gists{/gist_id}",
      "starred_url" => "https://api.github.com/users/StephenOTT/starred{/owner}{/repo}",
      "subscriptions_url" => "https://api.github.com/users/StephenOTT/subscriptions",
      "organizations_url" => "https://api.github.com/users/StephenOTT/orgs",
      "repos_url" => "https://api.github.com/users/StephenOTT/repos",
      "events_url" => "https://api.github.com/users/StephenOTT/events{/privacy}",
      "received_events_url" => "https://api.github.com/users/StephenOTT/received_events",
      "type" => "User",
      "site_admin" => false
    },
    "milestone" => {
      "url" => "https://api.github.com/repos/StephenOTT/Test1/milestones/2",
      "labels_url" => "https://api.github.com/repos/StephenOTT/Test1/milestones/2/labels",
      "id" => 583126,
      "number" => 2,
      "title" => "Feature X532",
      "description" => " =>dart: 47 days",
      "creator" => {
        "login" => "StephenOTT",
        "id" => 1994838,
        "avatar_url" => "https://avatars.githubusercontent.com/u/1994838?",
        "gravatar_id" => "365f114d7010e905f4b47865da4d0d1e",
        "url" => "https://api.github.com/users/StephenOTT",
        "html_url" => "https://github.com/StephenOTT",
        "followers_url" => "https://api.github.com/users/StephenOTT/followers",
        "following_url" => "https://api.github.com/users/StephenOTT/following{/other_user}",
        "gists_url" => "https://api.github.com/users/StephenOTT/gists{/gist_id}",
        "starred_url" => "https://api.github.com/users/StephenOTT/starred{/owner}{/repo}",
        "subscriptions_url" => "https://api.github.com/users/StephenOTT/subscriptions",
        "organizations_url" => "https://api.github.com/users/StephenOTT/orgs",
        "repos_url" => "https://api.github.com/users/StephenOTT/repos",
        "events_url" => "https://api.github.com/users/StephenOTT/events{/privacy}",
        "received_events_url" => "https://api.github.com/users/StephenOTT/received_events",
        "type" => "User",
        "site_admin" => false
      },
      "open_issues" => 1,
      "closed_issues" => 0,
      "state" => "open",
      "created_at" => "2014-02-28T02:21:28Z",
      "updated_at" => "2014-03-20T02:23:50Z",
      "due_on" => "2014-04-25T07:00:00Z"
    },
    "comments" => 8,
    "created_at" => "2014-02-26T05:23:42Z",
    "updated_at" => "2014-05-02T18:48:57Z",
    "closed_at" => nil,
    "body" => " =>clock1: 5min | Super easy, no glitch, Setting-up local environment for GitHub-TimeTracker\r\n\r\n"
  },
  "comment" => {
    "url" => "https://api.github.com/repos/StephenOTT/Test1/issues/comments/42064897",
    "html_url" => "https://github.com/StephenOTT/Test1/issues/9#issuecomment-42064897",
    "issue_url" => "https://api.github.com/repos/StephenOTT/Test1/issues/9",
    "id" => 42064897,
    "user" => {
      "login" => "StephenOTT",
      "id" => 1994838,
      "avatar_url" => "https://avatars.githubusercontent.com/u/1994838?",
      "gravatar_id" => "365f114d7010e905f4b47865da4d0d1e",
      "url" => "https://api.github.com/users/StephenOTT",
      "html_url" => "https://github.com/StephenOTT",
      "followers_url" => "https://api.github.com/users/StephenOTT/followers",
      "following_url" => "https://api.github.com/users/StephenOTT/following{/other_user}",
      "gists_url" => "https://api.github.com/users/StephenOTT/gists{/gist_id}",
      "starred_url" => "https://api.github.com/users/StephenOTT/starred{/owner}{/repo}",
      "subscriptions_url" => "https://api.github.com/users/StephenOTT/subscriptions",
      "organizations_url" => "https://api.github.com/users/StephenOTT/orgs",
      "repos_url" => "https://api.github.com/users/StephenOTT/repos",
      "events_url" => "https://api.github.com/users/StephenOTT/events{/privacy}",
      "received_events_url" => "https://api.github.com/users/StephenOTT/received_events",
      "type" => "User",
      "site_admin" => false
    },
    "created_at" => "2014-05-02T09:00:00Z",
    "updated_at" => "2014-05-02T18:48:57Z",
    "body" => ":alarm_clock: may 2 at 7:59pm | Reminder Text"
  },
  "repository" => {
    "id" => 10681593,
    "name" => "Test1",
    "full_name" => "StephenOTT/Test1",
    "owner" => {
      "login" => "StephenOTT",
      "id" => 1994838,
      "avatar_url" => "https://avatars.githubusercontent.com/u/1994838?",
      "gravatar_id" => "365f114d7010e905f4b47865da4d0d1e",
      "url" => "https://api.github.com/users/StephenOTT",
      "html_url" => "https://github.com/StephenOTT",
      "followers_url" => "https://api.github.com/users/StephenOTT/followers",
      "following_url" => "https://api.github.com/users/StephenOTT/following{/other_user}",
      "gists_url" => "https://api.github.com/users/StephenOTT/gists{/gist_id}",
      "starred_url" => "https://api.github.com/users/StephenOTT/starred{/owner}{/repo}",
      "subscriptions_url" => "https://api.github.com/users/StephenOTT/subscriptions",
      "organizations_url" => "https://api.github.com/users/StephenOTT/orgs",
      "repos_url" => "https://api.github.com/users/StephenOTT/repos",
      "events_url" => "https://api.github.com/users/StephenOTT/events{/privacy}",
      "received_events_url" => "https://api.github.com/users/StephenOTT/received_events",
      "type" => "User",
      "site_admin" => false
    },
    "private" => false,
    "html_url" => "https://github.com/StephenOTT/Test1",
    "description" => "Test1",
    "fork" => false,
    "url" => "https://api.github.com/repos/StephenOTT/Test1",
    "forks_url" => "https://api.github.com/repos/StephenOTT/Test1/forks",
    "keys_url" => "https://api.github.com/repos/StephenOTT/Test1/keys{/key_id}",
    "collaborators_url" => "https://api.github.com/repos/StephenOTT/Test1/collaborators{/collaborator}",
    "teams_url" => "https://api.github.com/repos/StephenOTT/Test1/teams",
    "hooks_url" => "https://api.github.com/repos/StephenOTT/Test1/hooks",
    "issue_events_url" => "https://api.github.com/repos/StephenOTT/Test1/issues/events{/number}",
    "events_url" => "https://api.github.com/repos/StephenOTT/Test1/events",
    "assignees_url" => "https://api.github.com/repos/StephenOTT/Test1/assignees{/user}",
    "branches_url" => "https://api.github.com/repos/StephenOTT/Test1/branches{/branch}",
    "tags_url" => "https://api.github.com/repos/StephenOTT/Test1/tags",
    "blobs_url" => "https://api.github.com/repos/StephenOTT/Test1/git/blobs{/sha}",
    "git_tags_url" => "https://api.github.com/repos/StephenOTT/Test1/git/tags{/sha}",
    "git_refs_url" => "https://api.github.com/repos/StephenOTT/Test1/git/refs{/sha}",
    "trees_url" => "https://api.github.com/repos/StephenOTT/Test1/git/trees{/sha}",
    "statuses_url" => "https://api.github.com/repos/StephenOTT/Test1/statuses/{sha}",
    "languages_url" => "https://api.github.com/repos/StephenOTT/Test1/languages",
    "stargazers_url" => "https://api.github.com/repos/StephenOTT/Test1/stargazers",
    "contributors_url" => "https://api.github.com/repos/StephenOTT/Test1/contributors",
    "subscribers_url" => "https://api.github.com/repos/StephenOTT/Test1/subscribers",
    "subscription_url" => "https://api.github.com/repos/StephenOTT/Test1/subscription",
    "commits_url" => "https://api.github.com/repos/StephenOTT/Test1/commits{/sha}",
    "git_commits_url" => "https://api.github.com/repos/StephenOTT/Test1/git/commits{/sha}",
    "comments_url" => "https://api.github.com/repos/StephenOTT/Test1/comments{/number}",
    "issue_comment_url" => "https://api.github.com/repos/StephenOTT/Test1/issues/comments/{number}",
    "contents_url" => "https://api.github.com/repos/StephenOTT/Test1/contents/{+path}",
    "compare_url" => "https://api.github.com/repos/StephenOTT/Test1/compare/{base}...{head}",
    "merges_url" => "https://api.github.com/repos/StephenOTT/Test1/merges",
    "archive_url" => "https://api.github.com/repos/StephenOTT/Test1/{archive_format}{/ref}",
    "downloads_url" => "https://api.github.com/repos/StephenOTT/Test1/downloads",
    "issues_url" => "https://api.github.com/repos/StephenOTT/Test1/issues{/number}",
    "pulls_url" => "https://api.github.com/repos/StephenOTT/Test1/pulls{/number}",
    "milestones_url" => "https://api.github.com/repos/StephenOTT/Test1/milestones{/number}",
    "notifications_url" => "https://api.github.com/repos/StephenOTT/Test1/notifications{?since,all,participating}",
    "labels_url" => "https://api.github.com/repos/StephenOTT/Test1/labels{/name}",
    "releases_url" => "https://api.github.com/repos/StephenOTT/Test1/releases{/id}",
    "created_at" => "2013-06-14T04:12:55Z",
    "updated_at" => "2013-12-15T22:46:05Z",
    "pushed_at" => "2013-12-15T22:46:04Z",
    "git_url" => "git://github.com/StephenOTT/Test1.git",
    "ssh_url" => "git@github.com:StephenOTT/Test1.git",
    "clone_url" => "https://github.com/StephenOTT/Test1.git",
    "svn_url" => "https://github.com/StephenOTT/Test1",
    "homepage" => "",
    "size" => 128,
    "stargazers_count" => 1,
    "watchers_count" => 1,
    "language" => nil,
    "has_issues" => true,
    "has_downloads" => true,
    "has_wiki" => true,
    "forks_count" => 0,
    "mirror_url" => nil,
    "open_issues_count" => 3,
    "forks" => 0,
    "open_issues" => 3,
    "watchers" => 1,
    "default_branch" => "master"
  },
  "sender" => {
    "login" => "StephenOTT",
    "id" => 1994838,
    "avatar_url" => "https://avatars.githubusercontent.com/u/1994838?",
    "gravatar_id" => "365f114d7010e905f4b47865da4d0d1e",
    "url" => "https://api.github.com/users/StephenOTT",
    "html_url" => "https://github.com/StephenOTT",
    "followers_url" => "https://api.github.com/users/StephenOTT/followers",
    "following_url" => "https://api.github.com/users/StephenOTT/following{/other_user}",
    "gists_url" => "https://api.github.com/users/StephenOTT/gists{/gist_id}",
    "starred_url" => "https://api.github.com/users/StephenOTT/starred{/owner}{/repo}",
    "subscriptions_url" => "https://api.github.com/users/StephenOTT/subscriptions",
    "organizations_url" => "https://api.github.com/users/StephenOTT/orgs",
    "repos_url" => "https://api.github.com/users/StephenOTT/repos",
    "events_url" => "https://api.github.com/users/StephenOTT/events{/privacy}",
    "received_events_url" => "https://api.github.com/users/StephenOTT/received_events",
    "type" => "User",
    "site_admin" => false
  }
}





gh_authenticate("USERNAME", "PASSWORD")
# create_gh_hook("StephenOTT/Test1")
# puts get_gh_user_emails.map {|email| email[:email]} 
process_request(rawDataValue, "US/Eastern")
