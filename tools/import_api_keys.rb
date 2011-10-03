#!/usr/bin/env ruby

require "mongo"

db = Mongo::Connection.new("localhost").db("twitter")

STDIN.each_line do |line|
	tmp = line.chomp.split ","
	db["api_key"].insert({:key => tmp[0], :secret => tmp[1]})
end
