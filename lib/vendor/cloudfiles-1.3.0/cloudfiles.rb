#!/usr/bin/env ruby
# 
# == Cloud Files API
# ==== Connects Ruby Applications to Rackspace's {Mosso Cloud Files service}[http://www.mosso.com/cloudfiles.jsp]
# Initial work by Major Hayden <major.hayden@rackspace.com>
# 
# Subsequent work by H. Wade Minter <wade.minter@rackspace.com>
#
#   Copyright (C) 2008 Rackspace US, Inc.
#  
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#  
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#  
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#  
# Except as contained in this notice, the name of Rackspace US, Inc. shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization from Rackspace US, Inc.
#
# ----
# 
# === Documentation & Examples
# To begin reviewing the available methods and examples, peruse the README file, or begin by looking at documentation for the 
# CloudFiles::Connection class.
#
# The CloudFiles class is the base class.  Not much of note happens here.
# To create a new CloudFiles connection, use the CloudFiles::Connection.new('user_name', 'api_key') method.
module CloudFiles
 
  VERSION = '1.3.0'
  require 'net/http'
  require 'net/https'
  require 'rexml/document'
  require 'uri'
  require 'digest/md5'
  require 'jcode' 
  require 'time'
  require 'rubygems'
  require 'mime/types'
 
  $KCODE = 'u'
 
  $:.unshift(File.dirname(__FILE__))
  require 'cloudfiles/authentication'
  require 'cloudfiles/connection'
  require 'cloudfiles/container'
  require 'cloudfiles/storage_object'
 
end
 
 
 
class SyntaxException             < StandardError # :nodoc:
end
class ConnectionException         < StandardError # :nodoc:
end
class AuthenticationException     < StandardError # :nodoc:
end
class InvalidResponseException    < StandardError # :nodoc:
end
class NonEmptyContainerException  < StandardError # :nodoc:
end
class NoSuchObjectException       < StandardError # :nodoc:
end
class NoSuchContainerException    < StandardError # :nodoc:
end
class NoSuchAccountException      < StandardError # :nodoc:
end
class MisMatchedChecksumException < StandardError # :nodoc:
end
class IOException                 < StandardError # :nodoc:
end
class CDNNotEnabledException      < StandardError # :nodoc:
end
class ObjectExistsException       < StandardError # :nodoc:
end
class ExpiredAuthTokenException   < StandardError # :nodoc:
end