#!/usr/bin/env ruby

require "twitter"
require "mongo"
require "date"
require "logger"

class TwitterCrawler
	def initialize(server, gateway, opts = {})
		@server = server
		@gateway = gateway
		@opts = opts
		@opts[:threads] ||= 10
		@opts[:get_friend] ||= false

		@db = Mongo::Connection.new(@server, nil, :pool_size => @opts[:threads]).db("twitter")

		@log = Logger.new(STDOUT)
		@log.level = Logger::DEBUG

		Twitter.configure do |config|
			config.gateway = "twitter1-nickhsutw.apigee.com"
		end

		@log.debug @opts.inspect
	end

	def start
		@log.info Twitter.rate_limit_status.inspect
		
		threads = []
		(1..@opts[:threads]).each do
			@log.info "start new thread"
			threads << Thread.new {
				start_fetch
			}
			sleep(10) # avoid get dup user data
		end

		threads.each do |t|
			t.join
		end
	end

	private
	
	def is_active(last_updated)
		#update after 7 days before
		return (DateTime.now - last_updated).to_i <= 7
	end

	def start_fetch
		loop do 
			user_datas = @db['user'].find({
				"$and" => [
					{"$or" => [
						{"is_active" => {"$exists" => false}},
						{"is_active" => true}
			]},
				{"$or" => [
					{"in_process" => {"$exists" => false}},
					{"in_process" => false}
			]}
			]}).limit(100).to_a
			
			user_datas.each do |user_data|
				@db['user'].update(
					{"id" => user_data["id"]},
					{"$set" => {'in_process' => true}},
				)
			end

			user_datas.each do |user_data|	
				begin
					if @opts[:get_friend]
						@log.info "get friends id = #{user_data["id"]}"
						Twitter.friend_ids(user_data["id"])['ids'].each do |friend_id|
							@db['user'].insert({:id => friend_id})
						end
					end

					@log.info "get posts id = #{user_data["id"]}"
					new_posts = Twitter.user_timeline(user_data["id"], {:count => 200, :trim_user => true, :include_rts => true})

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
					@db['user'].update({:id => user_data['id']}, user_data)
				rescue Twitter::Unauthorized => ex
					@log.info ex.to_s

					user_data['is_active'] = false
					@db['user'].update({:id => user_data['id']}, user_data)
				rescue Twitter::BadRequest => ex
					@log.info ex.to_s
					@log.info "sleep..."
					sleep(60 * 5)

					@log.info Twitter.rate_limit_status.inspect
					retry
				rescue Exception => ex
					@log.info ex.to_s
					retry
				end
			end
		end
	end
end

GET_FRIEND = true
SERVER = "96.43.137.2"
GATEWAY = "twitter1-nickhsutw.apigee.com"

tc = TwitterCrawler.new(SERVER, GATEWAY, :threads => 20, :get_friend => GET_FRIEND)
tc.start
