#!/usr/bin/env ruby

require "twitter"
require "mongo"
require "date"
require "logger"

def is_active(last_updated)
	#update after 7 days before
	return (DateTime.now - last_updated).to_i <= 7
end

GET_FRIENDS = false
SERVER = "linux.cs.ccu.edu.tw"

log = Logger.new(STDOUT)
log.level = Logger::DEBUG

db = Mongo::Connection.new(SERVER).db("twitter")

#get api key
api_key = db["api_key"].find_and_modify(
	:query => {"in_used" => false},
	:update => {"$set" => {"in_used" => true}}
)

log.debug api_key.inspect

#set API key
Twitter.configure do |config|
	config.consumer_key = api_key['consumer_key']
	config.consumer_secret = api_key["consumer_secret"]
	config.oauth_token = api_key["oauth_token"]
	config.oauth_token_secret = api_key["oauth_token_secret"]
end
log.info Twitter.rate_limit_status.inspect
	
#db["api_key"].update(
#	{:consumer_key => api_key["consumer_key"]},
#	{"$set" => {"in_used" => false}}
#)

skip_size = 0
loop do 
	user_datas = db['user'].find({
		"$and" => [
			{"$or" => [
				{"is_active" => {"$exists" => false}},
				{"is_active" => true}
			]},
			{"$or" => [
				{"in_process" => {"$exists" => false}},
				{"in_process" => false}
			]}
		]}).skip(skip_size).limit(100).to_a
	db['user'].update(
		{"id" => {"$in" => user_datas.map {|x| x['id']}}},
		{"$set" => {'in_process' => true}},
		{:multi => true}
	)
	
	user_datas.each do |user_data|	
		log.info "start fetch data id = #{user_data["id"]}"
		begin
			if GET_FRIENDS
				log.info "get friends id = #{user_data["id"]}"
				Twitter.friend_ids(user_data["id"])['ids'].each { |friend_id| db['user'].insert({:id => friend_id}) }
			end

			new_posts = Twitter.user_timeline(user_data["id"], {:count => 200, :trim_user => true, :include_rts => true})
			
			log.info "end fetch data id = #{user_data["id"]}"
			#log.debug new_posts.inspect
			
			if new_posts.empty?
				user_data['is_active'] = false
			else
				user_data['is_active'] = is_active(DateTime.parse(new_posts.first['created_at']))
			end
			
			if user_data['posts'].nil?
				user_data['posts'] = new_posts
			else
				user_data['posts'] += new_posts
				user_data['posts'].uniq!
			end

			user_data['last_updated_at'] = Time.now
			user_data['in_process'] = false
			db['user'].update({:id => user_data['id']}, user_data)
		rescue Twitter::Unauthorized => ex
			log.info ex.to_s
			
			user_data['is_active'] = false
			db['user'].update({:id => user_data['id']}, user_data)
		rescue Twitter::BadGateway => ex
			log.info ex.to_s
			sleep(10)
			retry
		rescue Twitter::BadRequest => ex
			log.info ex.to_s
			log.info "sleep..."
			sleep(60 * 30)
				
			log.info Twitter.rate_limit_status.inspect
			retry
		end
	end

	puts "finish a round"
	skip_size += 100
end
