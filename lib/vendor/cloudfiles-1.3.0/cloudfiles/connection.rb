#   Copyright (C) 2008 Rackspace US, Inc.
#  
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#  
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#  
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#  
# Except as contained in this notice, the name of Rackspace US, Inc. shall not be used in advertising or otherwise to promote the sale, use or other dealings in this Software without prior written authorization from Rackspace US, Inc.

module CloudFiles
  class Connection
    
    # Authentication key provided when the CloudFiles class was instantiated
    attr_reader :authkey
 
    # Token returned after a successful authentication
    attr_accessor :authtoken
 
    # Authentication username provided when the CloudFiles class was instantiated
    attr_reader :authuser
 
    # Hostname of the CDN management server
    attr_accessor :cdnmgmthost
 
    # Path for managing containers on the CDN management server
    attr_accessor :cdnmgmtpath
 
    # Array of requests that have been made so far
    attr_reader :reqlog
 
    # Hostname of the storage server
    attr_accessor :storagehost
 
    # Path for managing containers/objects on the storage server
    attr_accessor :storagepath
    
    # Instance variable that is set when authorization succeeds
    attr_accessor :authok
    
    # The total size in bytes under this connection
    attr_reader :bytes
    
    # The total number of containers under this connection
    attr_reader :count
 
    # Creates a new CloudFiles::Connection object.  Uses CloudFiles::Authentication to perform the login for the connection.
    # The authuser is the Mosso username, the authkey is the Mosso API key.
    #
    # Setting the optional retry_auth variable to false will cause an exception to be thrown if your authorization token expires.
    # Otherwise, it will attempt to reauthenticate.
    #
    # This will likely be the base class for most operations.
    #
    #   cf = CloudFiles::Connection.new(MY_USERNAME, MY_API_KEY)
    def initialize(authuser,authkey,retry_auth = true) 
      @authuser = authuser
      @authkey = authkey
      @retry_auth = retry_auth
      @authok = false
      @http = {}
      @reqlog = []
      CloudFiles::Authentication.new(self)
    end
 
    # Returns true if the authentication was successful and returns false otherwise.
    #
    #   cf.authok?
    #   => true
    def authok?
      @authok
    end
 
    # Returns an CloudFiles::Container object that can be manipulated easily.  Throws a NoSuchContainerException if
    # the container doesn't exist.
    #
    #    container = cf.container('test')
    #    container.count
    #    => 2
    def container(name)
      CloudFiles::Container.new(self,name)
    end
    alias :get_container :container
 
    # Sets instance variables for the bytes of storage used for this account/connection, as well as the number of containers
    # stored under the account.  Returns a hash with :bytes and :count keys, and also sets the instance variables.
    #
    #   cf.get_info
    #   => {:count=>8, :bytes=>42438527}
    #   cf.bytes
    #   => 42438527    
    def get_info
      response = cfreq("HEAD",@storagehost,@storagepath)
      raise InvalidResponseException, "Unable to obtain account size" unless (response.code == "204")
      @bytes = response["x-account-bytes-used"].to_i
      @count = response["x-account-container-count"].to_i
      {:bytes => @bytes, :count => @count}
    end
    
    # Gathers a list of the containers that exist for the account and returns the list of container names
    # as an array.  If no containers exist, an empty array is returned.  Throws an InvalidResponseException
    # if the request fails.
    #
    # If you supply the optional limit and marker parameters, the call will return the number of containers
    # specified in limit, starting after the object named in marker.
    #
    #   cf.containers
    #   => ["backup", "Books", "cftest", "test", "video", "webpics"] 
    #
    #   cf.containers(2,'cftest')
    #   => ["test", "video"]
    def containers(limit=0,marker="")
      paramarr = []
      paramarr << ["limit=#{URI.encode(limit.to_s)}"] if limit.to_i > 0
      paramarr << ["offset=#{URI.encode(marker.to_s)}"] unless marker.to_s.empty?
      paramstr = (paramarr.size > 0)? paramarr.join("&") : "" ;
      response = cfreq("GET",@storagehost,"#{@storagepath}?#{paramstr}")
      return [] if (response.code == "204")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "200")
      response.body.to_a.map { |x| x.chomp }
    end
    alias :list_containers :containers
 
    # Retrieves a list of containers on the account along with their sizes (in bytes) and counts of the objects
    # held within them.  If no containers exist, an empty hash is returned.  Throws an InvalidResponseException
    # if the request fails.
    #
    # If you supply the optional limit and marker parameters, the call will return the number of containers
    # specified in limit, starting after the object named in marker.
    # 
    #   cf.containers_detail              
    #   => { "container1" => { :bytes => "36543", :count => "146" }, 
    #        "container2" => { :bytes => "105943", :count => "25" } }
    def containers_detail(limit=0,marker="")
      paramarr = []
      paramarr << ["limit=#{URI.encode(limit.to_s)}"] if limit.to_i > 0
      paramarr << ["offset=#{URI.encode(marker.to_s)}"] unless marker.to_s.empty?
      paramstr = (paramarr.size > 0)? paramarr.join("&") : "" ;
      response = cfreq("GET",@storagehost,"#{@storagepath}?format=xml&#{paramstr}")
      return {} if (response.code == "204")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "200")
      doc = REXML::Document.new(response.body)
      detailhash = {}
      doc.elements.each("account/container/") { |c|
        detailhash[c.elements["name"].text] = { :bytes => c.elements["bytes"].text, :count => c.elements["count"].text  }
      }
      doc = nil
      return detailhash
    end
    alias :list_containers_info :containers_detail
 
    # Returns true if the requested container exists and returns false otherwise.
    # 
    #   cf.container_exists?('good_container')
    #   => true
    #  
    #   cf.container_exists?('bad_container')
    #   => false
    def container_exists?(containername)
      response = cfreq("HEAD",@storagehost,"#{@storagepath}/#{containername}")
      return (response.code == "204")? true : false ;
    end
 
    # Creates a new container and returns the CloudFiles::Container object.  Throws an InvalidResponseException if the 
    # request fails.
    #
    # Slash (/) and question mark (?) are invalid characters, and will be stripped out.  The container name is limited to 
    # 256 characters or less.
    #
    #   container = cf.create_container('new_container')
    #   container.name
    #   => "new_container"
    #
    #   container = cf.create_container('bad/name')
    #   => SyntaxException: Container name cannot contain the characters '/' or '?'
    def create_container(containername)
      raise SyntaxException, "Container name cannot contain the characters '/' or '?'" if containername.match(/[\/\?]/)
      raise SyntaxException, "Container name is limited to 256 characters" if containername.length > 256
      response = cfreq("PUT",@storagehost,"#{@storagepath}/#{containername}")
      raise InvalidResponseException, "Unable to create container #{containername}" unless (response.code == "201" || response.code == "202")
      CloudFiles::Container.new(self,containername)
    end
 
    # Deletes a container from the account.  Throws a NonEmptyContainerException if the container still contains
    # objects.  Throws a NoSuchContainerException if the container doesn't exist.
    # 
    #   cf.delete_container('new_container')
    #   => true
    #
    #   cf.delete_container('video')
    #   => NonEmptyContainerException: Container video is not empty
    #
    #   cf.delete_container('nonexistent')
    #   => NoSuchContainerException: Container nonexistent does not exist
    def delete_container(containername)
      response = cfreq("DELETE",@storagehost,"#{@storagepath}/#{containername}")
      raise NonEmptyContainerException, "Container #{containername} is not empty" if (response.code == "409")
      raise NoSuchContainerException, "Container #{containername} does not exist" unless (response.code == "204")
      true
    end
 
    # Gathers a list of public (CDN-enabled) containers that exist for an account and returns the list of container names
    # as an array.  If no containers are public, an empty array is returned.  Throws a InvalidResponseException if
    # the request fails.
    #
    # If you pass the optional argument as true, it will only show containers that are CURRENTLY being shared on the CDN, 
    # as opposed to the default behavior which is to show all containers that have EVER been public.
    #
    #   cf.public_containers
    #   => ["video", "webpics"]
    def public_containers(enabled_only = false)
      paramstr = enabled_only == true ? "enabled_only=true" : ""
      response = cfreq("GET",@cdnmgmthost,"#{@cdnmgmtpath}?#{paramstr}")
      return [] if (response.code == "204")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "200")
      response.body.to_a.map { |x| x.chomp }
    end
 
    # This method actually makes the HTTP calls out to the server
    def cfreq(method,server,path,headers = {},data = nil,attempts = 0,&block) # :nodoc:
      start = Time.now
      hdrhash = headerprep(headers)
      path = URI.escape(path)
      start_http(server,path,hdrhash)
      request = Net::HTTP.const_get(method.to_s.capitalize).new(path,hdrhash)
      if data
        if data.respond_to?(:read)
          request.body_stream = data
        else
          request.body = data
        end
        request.content_length = data.respond_to?(:lstat) ? data.stat.size : data.size
      else
        request.content_length = 0
      end
      response = @http[server].request(request,&block)
      raise ExpiredAuthTokenException if response.code == "401"
      response
    rescue Errno::EPIPE, Timeout::Error, Errno::EINVAL, EOFError
      # Server closed the connection, retry
      raise ConnectionException, "Unable to reconnect to #{server} after #{count} attempts" if attempts >= 5
      attempts += 1
      @http[server].finish
      start_http(server,path,headers)
      retry
    rescue ExpiredAuthTokenException
      raise ConnectionException, "Authentication token expired and you have requested not to retry" if @retry_auth == false
      CloudFiles::Authentication.new(self)
      retry
    end
    
    private
    
    # Sets up standard HTTP headers
    def headerprep(headers = {}) # :nodoc:
      default_headers = {}
      default_headers["X-Auth-Token"] = @authtoken if (authok? && @account.nil?)
      default_headers["X-Storage-Token"] = @authtoken if (authok? && !@account.nil?)
      default_headers["Connection"] = "Keep-Alive"
      default_headers["User-Agent"] = "Ruby-CloudFiles/#{VERSION}"
      default_headers.merge(headers)
    end
    
    # Starts (or restarts) the HTTP connection
    def start_http(server,path,headers) # :nodoc:
      if (@http[server].nil?)
        begin
          @http[server] = Net::HTTP.new(server,443)
          @http[server].use_ssl = true
          @http[server].verify_mode = OpenSSL::SSL::VERIFY_NONE
          @http[server].start
        rescue
          raise ConnectionException, "Unable to connect to #{server}"
        end
      end
    end
 
  end
 
end