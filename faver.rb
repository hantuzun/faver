# coding: utf-8

require 'twitter'
require 'klout'
require 'colorize'
require 'open-uri'
require 'ruby-xxhash'
require_relative 'pipe.rb'

def connection?
	begin
		true if open("https://www.twitter.com/")
	rescue
		false
	end
end

def responsive?(user)
	user.followers_count < user.friends_count * 5
end

def klout_score(screen_name)
	klout_id = Klout::Identity.find_by_screen_name(screen_name)
	user = Klout::User.new(klout_id.id)
	user.score.score.to_i.to_s

	# Return 0 as the score if Klout returns an 404 Exception
	# http://klout.com/s/developers/v2#errors
	rescue
		0
end 

def influential?(screen_name)
	score = klout_score(screen_name).to_i
	50 <= score
end

def puts_heading(topics)
	system "clear"
	puts "\t\t\t\t\t\t\t ★  faver ★".bold.colorize(:yellow)
	puts
	print "Watching topics: "
	puts topics
	puts
end

def puts_tweet(tweet)
	puts
	user_info = tweet.user.name + "   @" + tweet.user.screen_name 
	user_info += "   (" +  klout_score(tweet.user.screen_name) + ")"
	puts user_info.colorize(:white)
	puts tweet.text.colorize(:light_white)
	puts '★'.bold.colorize(:yellow)
end

def puts_error
	puts
	puts "<error>".colorize(:red)
	puts $!.inspect.colorize(:red)
	puts "</error>".colorize(:red)	
end

###############################################################################

Thread.new do
	loop do
		exit! if gets.chomp == 'q'
	end
end

until connection?
	puts 
	puts "Could not connect to twitter.com"
	puts "trying again in 10 seconds"
	sleep 10
end

Klout.api_key = File.read('keys/klout_api_key')

config = {
	consumer_key: File.read('keys/twitter_consumer_key'),
	consumer_secret: File.read('keys/twitter_consumer_secret'),
	access_token: File.read('keys/twitter_access_token'),
	access_token_secret: File.read('keys/twitter_access_token_secret') 
}

rest = Twitter::REST::Client.new config
stream = Twitter::Streaming::Client.new(config)

# topics to watch
topics = ['#entrepreneurs', '#entrepreneurship', '#innovation', 
		'#startup', '#startups', '#socent',	'#socialgood',
		'#machinelearning', '#datascience']
topics = topics.join(', ')

# Initial display 
puts_heading(topics)

user_pipe = Pipe.new("user_pipe")
tweet_pipe = Pipe.new("tweet_pipe")

while true
	begin	
		stream.filter(	:track => topics,
						:language => "en",
						:filter_level => "medium"
						) do |tweet|

		if tweet.is_a?(Twitter::Tweet)
			if user_pipe.exclude?(tweet.user.screen_name)
				if tweet_pipe.exclude?(XXhash.xxh32(tweet.text[0..40], 12345).to_s)
					if tweet.text.count('#') <= 2
						if tweet.text.count('@') <= 2
							if tweet.retweeted_status.id.to_s == ""
								if tweet.in_reply_to_user_id == nil
									if responsive?(tweet.user)
										if influential?(tweet.user.screen_name)
											rest.fav tweet
											puts_tweet(tweet)
											user_pipe << tweet.user.screen_name
											tweet_pipe << XXhash.xxh32(tweet.text[0..40], 12345).to_s
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
	rescue
		puts_error
	end
end