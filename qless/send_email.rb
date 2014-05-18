require 'rest-client'

class MyJobClass
  def self.perform(job)
  	# Future code for loading html template
	# file = File.open("path-to-file.tar.gz", "txt")
	# contents = file.read

		RestClient.post "https://api:key-6iqs3vfdn7pnkgxpj4ip4-1iyve-ljm3"\
		"@api.mailgun.net/v2/sandbox7a90f2af1ae6406bbd6f4ef9cff652b3.mailgun.org/messages",
		"from" => "GitHub Reminder <postmaster@sandbox7a90f2af1ae6406bbd6f4ef9cff652b3.mailgun.org>",
		"to" => "Stephen Russett <stephenrussett@gmail.com>",
		"subject" => "GitHub Reminder - 1",
		"text" => "This is a Github-Reminder"
  end
end