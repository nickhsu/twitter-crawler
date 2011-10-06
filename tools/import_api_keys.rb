#!/usr/bin/env ruby

require "mongo"

SERVER = 'linux.cs.ccu.edu.tw'

db = Mongo::Connection.new(SERVER).db("twitter")

STDIN.each_line do |line|
	tmp = line.chomp.split ","
	db["api_key"].insert({
			:consumer_key => tmp[0],
			:consumer_secret => tmp[1],
			:oauth_token => tmp[2],
			:oauth_token_secret => tmp[3],
			:in_used => false
	})
end
