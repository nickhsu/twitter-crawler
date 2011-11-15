#!/usr/bin/env ruby

require "mongo"

SERVER = "96.43.137.2"

db = Mongo::Connection.new(SERVER).db("twitter")

db["api_key"].update(
	{},
	{"$set" => {"in_used" => false}},
	{:multi => true}
)
