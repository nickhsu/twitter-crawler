#!/usr/bin/env ruby

require 'pstore'

db = PStore.new('test.db')

db.transaction do
	(1..1000000).each do |i|
		db["xxxxxxxxxxxxxx#{i}"] = true
	end
end

=begin
db.transaction do 
	(1..10000).each do |i|
		p db[i]
	end
end
=end
