require 'bundler/setup'

require 'qless'
require 'rest-client'
require 'pp'


# Connect to localhost
# client = Qless::Client.new
# Connect to somewhere else
# client = Qless::Client.new(:host => 'localhost', :port => 6379)


class MyJobClass
  def self.perform(job)
    # job is an instance of `Qless::Job` and provides access to
    # job.data, a means to cancel the job (job.cancel), and more.
		RestClient.post "https://api:key-6iqs3vfdn7pnkgxpj4ip4-1iyve-ljm3"\
		"@api.mailgun.net/v2/sandbox7a90f2af1ae6406bbd6f4ef9cff652b3.mailgun.org/messages",
		"from" => "GitHub Reminder <postmaster@sandbox7a90f2af1ae6406bbd6f4ef9cff652b3.mailgun.org>",
		"to" => "Stephen Russett <stephenrussett@gmail.com>",
		"subject" => "GitHub Reminder - 1",
		"text" => "This is a Github-Reminder"
  end
end

# job = client.jobs['570ff64985364f24b398979aedfcc386']
# pp job.scheduleddate
# This referdependencies new or existing queue 'testing'
# queue = client.queues['testing']
# Let's add a job, with some data. Returns Job ID
# queue.put(MyJobClass, {:hello => 'howdy'}, :delay => 420)
# => "0c53b0404c56012f69fa482a1427ab7d"
# Now we can ask for a job
# job = queue.pop
# => <Qless::Job 0c53b0404c56012f69fa482a1427ab7d (MyJobClass / testing)>
# And we can do the work associated with it!
# job.perform
# client.close
# http://0.0.0.0:5678/jobs/7f81bbe64bcd4599b565c95c817cf363