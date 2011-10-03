#!/usr/bin/env ruby

require "twitter"
require "date"
require "awesome_print"

Twitter.configure do |config|
	config.consumer_key = "RrTp6MlXuw9vKctmMg7Q"
	config.consumer_secret = "Z5JWj9CMeLWgmBEA3pUVKMpXxpH1xgmKX19dNThU"
	config.oauth_token = "16683284-vr90dCwtVoAkTVv9XjSmZvBlX0ijXPXsfKLKGpiuq"
	config.oauth_token_secret = "f5aoihXB7wR7zjzqhMUNo9ke3QG5HATKOHFzHME4"
end

#puts Twitter.friend_ids("sferik").inspect
ap Twitter.user_timeline("sferik", {:count => 200, :trim_user => true, :include_rts => true})
