#!/usr/bin/env ruby

require "mongo"

SERVER = 'gaisq.cs.ccu.edu.tw'

db = Mongo::Connection.new(SERVER).db("twitter")

db["api_key"].update(
	{},
	{"$set" => {"in_used" => false}},
	{:multi => true}
)
