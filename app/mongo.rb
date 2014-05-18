require 'mongo'

module Mongo_Connection

	include Mongo

	def self.clear_mongo_collections
		@collReminders.remove
	end

	def self.addReminder(mongoPayload)
		@collReminders.insert(mongoPayload)
	end

	def self.mongo_Connect(url, port, dbName, collName)
		@client = MongoClient.new(url, port)
		@db = @client[dbName]
		@collReminders = @db[collName]
	end


end