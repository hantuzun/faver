# a Ruby 'pipe'
# works like a queue but only accepts unique elements
# and have a capacity of 100 items
# Thanks to https://gist.github.com/daddz/352509

class Pipe
	
	def initialize(file_name)
		@file_name = file_name
	end

	def push(obj)
		# if the item is not in the file
		if include?(obj) == false
			safe_open('a') do |file|
				file.write(obj + "\n")
			end
		end

		## if the item has more than 100 elements
		if length > 100
			# pop (the oldest item)
			pop
		end
	end

	# pipe << item
	alias << push

	# returns whether the item is in the file
	def include?(obj)
		content = nil
		safe_open('r') do |file|
			content = file.read 
		end
		content.include? obj
	end

	def exclude?(obj)
		! include?(obj)
	end

	private
	def length
		count = 0
		safe_open('r') do |file|
			count = file.read.count("\n")
		end
		count
	end

	private
	def safe_open(mode)
		File.open(@file_name, mode) do |file|
			file.flock(File::LOCK_EX)
			yield file
			file.flock(File::LOCK_UN)
		end
	end

	private
	def pop
		value = nil
		rest = nil
		safe_open('r') do |file|
			value = file.gets
			rest = file.read
		end
		safe_open('w+') do |file|
			file.write(rest)
		end
	end

end