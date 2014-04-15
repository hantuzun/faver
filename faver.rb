require 'twitter'
require 'klout'
require 'colorize'
require_relative 'pipe.rb'

system "clear"

def p_tweet(tweet)
	puts
	user_info = tweet.user.name + "   @" + tweet.user.screen_name 
	user_info += "   (" +  klout_score(tweet.user.screen_name) + ")"
	puts user_info.colorize(:white)
	puts tweet.text.colorize(:light_white)
	puts "*".bold.colorize(:yellow)
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

def responsive?(user)
	user.followers_count < user.friends_count * 5
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
topics = ['#entrepreneurs', '#innovation', '#coding', 
			'#startup', '#startups', '#socent', 
			'#socialgood', '#entrepreneurship',
			'#machinelearning', '#datascience']
topics = topics.join(', ')

puts "Topics to watch:"
puts topics
puts

pipe = Pipe.new("pipe")

while true
	begin	
		stream.filter(	:track => topics,
						:language => "en",
						:filter_level => "medium"
						) do |tweet|
		print " "

		if tweet.is_a?(Twitter::Tweet)
			if pipe.exclude?(tweet.user.screen_name)
				if tweet.text.count('#') < 4
					if tweet.retweeted_status.id.to_s == ""
						if tweet.in_reply_to_user_id == nil
							if responsive?(tweet.user)
								if influential?(tweet.user.screen_name)
									rest.fav tweet
									p_tweet(tweet)
									pipe. << tweet.user.screen_name
								end
							end
						end
					end
				end
			end
		end
	end
	rescue
		puts
		puts "<error>".colorize(:red)
		puts $!.inspect.colorize(:red)
		puts "</error>".colorize(:red)		
	end
end