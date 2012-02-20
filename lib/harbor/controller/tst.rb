#
# Ternary Search Tree
#

module Structures

	module TST

		class NotFound < Exception
		end

		class Node

			attr_reader :key, :value
			attr_reader	:left,:right, :ref, :tokens

			def initialize(key=nil, value=nil)
				@key 	= key
				@value  = value
				@left = @right = @ref = @tokens = nil
			end

			#
			# Returns true if Node has left or right
			#
			def children?
				(@left != nil) || (@right != nil)
			end

			#
			# Returns true if Node has ref
			#
			def ref?
				@ref != nil
			end

			#
			# Searches for key k and returns node if found.
			# Raises if key was not found.
			#
			# str must implement:
			# []
			#
			def node(str, index=0, len=str.length-1)
				k = str[index]

# puts "1. Searching for node w/ str=#{str.inspect}, index=#{index}, len=#{len} [#{k}]"

				if (k == @key) then
					if index == len
					  return self
					end

					if @ref
					  return @ref.node(str, index+1, len)
					end
				end
        if @key == "*"

					if @ref
					  return @ref.node(str, index+1, len)
					end

				elsif (k < @key) && @left
				  return @left.node(str, index, len)
				end

				if @right
				  return @right.node(str, index, len)
				end

				raise NotFound
			end

			#
			# Searches for str and returns node value if found.
			# Raises Structures::TST::NotFound if key was not found.
			#
			def search(str)
# puts "0. Searching for #{str.inspect} in #{self}"
				node(str).value
			end

			#
			# Returns true if key exists false if it doesnt.
			#
			def has_key?(str)
				node(str); true
			rescue NotFound
				false
			end

			#
			# Inserts str and value into tree.
			#
			# str must implement []
			#
			def insert(tokens, value=nil, index=0, len=tokens.size)
				k = tokens[index]

puts "Inserting: #{tokens.inspect} [#{k}]"

				if @key.nil?
				  puts "Setting @key = #{k.inspect} on #{self}"
				  @key = k
				  @tokens = tokens
			  else
			    if @key == "*"
  				  @key = k

            @left = Structures::TST::Node.new
            @left.insert(@tokens, @value, index, @tokens.size)

            @tokens = tokens

  				  if @ref
              @left.ref.insert(@left.tokens, @ref.value, index+1, @left.tokens.size)
  					end

  					@ref = Structures::TST::Node.new
  					@ref.insert(tokens, value, index+1, len)
  			  end
				end

				if k == @key then
					if (index + 1) < len then
puts "(#{index} + 1) < #{len} == true [#{k}] (ref = #{@ref})"
						@ref = if @ref
						  @ref
						else
						  puts "Creating new @ref node"
						  Structures::TST::Node.new
						end
						result = @ref.insert(tokens, value, index+1, len)
puts "After Insert: @ref = #{@ref}, @ref.left == #{@ref.left}, @ref.right == #{@ref.right}"
            result
					else
puts "@value = '#{value}'"
						@value = value
						@ref
					end
				elsif k < @key then
puts "Inserting Left: tokens=#{tokens.inspect}, value=#{value}, index=#{index}, len=#{len} (TOKEN=#{tokens[index]})"
					@left = Structures::TST::Node.new unless @left
					@left.insert(tokens, value, index, len)
				else
puts "Inserting Right: tokens=#{tokens.inspect}, value=#{value}, index=#{index}, len=#{len} (TOKEN=#{tokens[index]})"
					@right = Structures::TST::Node.new unless @right
					@right.insert(tokens, value, index, len)
				end

			end





#======================================
protected

	def to_str_connectors(path, dir, depth, out)
		e = depth

		e -= 1 while (e > 0 && dir[e - 1] == :center)

		if e > 0 then

			i   = 0
			co  = ' '

			while true
				out << co << (' ' * @@gap)
				i += 1

				break if i == e

				k = i

				k += 1 while (dir[k] == :center)

				if dir[i - 1] != :center then
					co = (dir[i - 1] == dir[k]) ? ' ' : '|'
				else
					p = path[i - 1]
					co = ((dir[k] != :left ? p.right : p.left) == nil) ? ' ' : '|'
				end
			end
		end

		e
	end

	def to_str_boxes(path, e, depth, out)
		while e < depth
			p  = path[e]
			e += 1
			sc = p.key
			out << "+--[#{sc.to_s.center(@@box_width)}]"
		end
	end

	def _to_str(out, path=[], dir=[], depth=0)

		path[depth] = self

		if right then
			dir[depth] = :right
			right._to_str(out, path, dir, depth+1)
			to_str_connectors(path, dir, depth+1, out)
			out << "|\n"
		end

		unless ref then
			e = to_str_connectors(path, dir, depth, out)
			to_str_boxes(path, e, depth+1, out)
			out << "+-->nil\n"
		else
			dir[depth] = :center
			ref._to_str(out, path, dir, depth+1)
		end

		if left then
			dir[depth] = :left
			to_str_connectors(path, dir, depth+1, out)
			out << "|\n"
			left._to_str(out, path, dir, depth+1)
		end

	end

public

	#
	# Vertical Pretty Printing for TST::Node
	#
	def to_str(box_width=1)
		@@box_width = box_width
		@@gap = 4 + @@box_width

		result = ''
		_to_str(result)
		result
	end

	def to_s(b_width=1)
		to_str(b_width)
	end





#======================================







		end

	end

end


tst = Structures::TST::Node.new

tst.insert(['accounts', 'bob', 'users', 'delete'], 10000)
tst.insert(['users'], 0)
tst.insert(['accounts'], 1)
tst.insert(['accounts', 'cow', 'users'], 50)
tst.insert(['accounts', '*', 'users'], 100)
tst.insert(['accounts', 'bob', 'users'], 900)


puts "********************************************************************"
puts tst
puts "********************************************************************"

# puts tst.search(['accounts'])
puts tst.search(['accounts', 'cow', 'users'])
puts tst.search(['accounts', '10', 'users'])
puts tst.search(['accounts', 'bob', 'users'])
puts tst.search(['accounts', 'bob', 'users', 'delete'])