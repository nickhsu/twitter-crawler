#!/usr/bin/env ruby

require "twitter"
require "mongo"
require "date"

def is_active(last_updated)
	#update after 7 days before
	return (DateTime.now - last_updated) <= 7
end

GET_FRIENDS = true
SERVER = "linux.cs.ccu.edu.tw"

db = Mongo::Connection.new(SERVER).db("twitter")

#get all api key
api_keys = db["api_key"].find().to_a

skip = 0
loop do 
	api_key = api_keys.pop 
	Twitter.configure do |config|
		config.consumer_key = api_key['consumer_key']
		config.consumer_secret = api_key["consumer_secret"]
	end
	api_keys.unshift api_key

	user_datas = db['user'].find({"is_active" => {"$exists" => false}}, {:skip => skip, :limit => 1000})
	#user_ids = db['user'].find("$and" => [{"is_active" => true}])

	user_datas.each do |user_data|	
		begin
			if GET_FRIENDS
				puts "get friends id = #{user_data["id"]}"
				Twitter.friend_ids(user_data["id"])['ids'].each { |friend_id| db['user'].insert({:id => friend_id}) }
			end

			new_posts = Twitter.user_timeline(user_data["id"], {:count => 200, :trim_user => true, :include_rts => true})
			user_data['is_active'] = is_active(DateTime.parse(new_posts.first['created_at']))
			
			if user_data['posts'].nil?
				user_data['posts'] = new_posts
			else
				user_data['posts'] += new_posts
				user_data['posts'].uniq!
			end

			user_data['last_updated_at'] = Time.now
			db['user'].update({:id => user_data['id']}, user_data)
		rescue Twitter::Unauthorized
		rescue Twitter::BadRequest
			puts "request limit, sleep..."
			sleep(60)

			api_key = api_keys.pop 
			Twitter.configure do |config|
				config.consumer_key = api_key['consumer_key']
				config.consumer_secret = api_key["consumer_secret"]
			end
			api_keys.unshift api_keys

			retry
		end
	end

	puts "finish a round"
	skip += 1000
end
