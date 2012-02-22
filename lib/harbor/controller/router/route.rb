if $0 == __FILE__
  require "action"
else
  require "harbor/controller/router/action"
end

module Harbor
  class Controller
    class Router      
      class Route

        PATH_SEPARATOR = /[\/;]/
        
        def self.expand(path)
          path.split(PATH_SEPARATOR).reject { |part| part.empty? }
			  end
			  
  			attr_reader :fragment, :action, :tokens, :match, :left , :right

  			def initialize(fragment = nil, action = nil)
  				@fragment 	= fragment
  				@action     = action
  				@tokens     = nil
  				
  				@match      = nil
  				@left       = nil
  				@right      = nil
  			end

  			def node(tokens, index = 0, length = tokens.length - 1)
  				part = tokens[index]
          
  				if part == @fragment || @fragment[0] == ?: then
					  return self if index == length
				    return @match.node(tokens, index + 1, length) if @match
  				end

          return @left.node(tokens, index, length) if @left && part < @fragment
				  return @right.node(tokens, index, length) if @right
  			end

  			#
  			# Searches for path and returns action if matched.
  			# Returns nil if not found.
  			#
  			def search(path)
  			  if result = node(path)
  			    result.action
			    else
			      nil
		      end
  			end

  			#
  			# Inserts str and value into tree.
  			#
  			# str must implement []
  			#
  			def insert(tokens, action = nil, index = 0, length = tokens.size)
  				part = tokens[index]

  				if @fragment.nil?
  				  assign! part, tokens
  			  elsif @fragment[0] == ?:
  			    replace! part, tokens
    			end

  				if part == @fragment then
  				  # We have a match!
  				  
  					if (index + 1) < length then
  					  # There are more fragments to consume.
  						(@match ||= Route.new).insert(tokens, action, index + 1, length)
  					else
              # There are no more fragments to consume.
  						@action = action
  					end
  				elsif part < @fragment then
  					(@left ||= Route.new).insert(tokens, action, index, length)
  				else
  				  (@right ||= Route.new).insert(tokens, action, index, length)
  				end
  			end
  			
  			def assign!(fragment, tokens)
  			  @fragment = fragment
  			  @tokens = tokens
			  end
			  
			  def replace!(fragment, tokens)
			    @fragment = fragment
				  
				  # Valid routes are always to the left of Wildcards.
          @left = Route.new
          @left.insert(@tokens, @action, index, @tokens.size)

          @tokens = tokens

          # If the Wildcard had additional fragments below it...
				  if @match
            @left.match.insert(@left.tokens, @match.action, index + 1, @left.tokens.size)
					end

          # Continue insertion of the new path.
					@match = Route.new
					@match.insert(tokens, action, index + 1, len)
				end
				
      end # Route
    end # Router
  end # Controller
end # Harbor