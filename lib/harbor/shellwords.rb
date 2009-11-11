require 'shellwords'

module Harbor
  ##
  # This is a backport of ruby-1.8.7's Shellwords.escape function to 1.8.6
  # 
  # It can be used to safely escape strings which will be passed to a shell:
  # 
  #   Shellwords.escape("file/with/spaces in name.txt") # => "file/with/spaces\\ in\\ name.txt"
  ##
  module Shellwords
    def escape(str)
      # An empty argument will be skipped, so return empty quotes.
      return "''" if str.empty?

      str = str.dup

      # Process as a single byte sequence because not all shell
      # implementations are multibyte aware.
      str.gsub!(/([^A-Za-z0-9_\-.,:\/@\n])/n, "\\\\\\1")

      # A LF cannot be escaped with a backslash because a backslash + LF
      # combo is regarded as line continuation and simply ignored.
      str.gsub!(/\n/, "'\n'")

      return str
    end
  end
end

unless Shellwords.respond_to?(:escape)
  Shellwords.send(:include, Harbor::Shellwords)
  Shellwords.send(:module_function, :escape)
end