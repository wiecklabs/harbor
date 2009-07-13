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
  class Container
 
    # Name of the container which corresponds to the instantiated container class
    attr_reader :name
 
    # Size of the container (in bytes)
    attr_reader :bytes
 
    # Number of objects in the container
    attr_reader :count
 
    # True if container is public, false if container is private
    attr_reader :cdn_enabled
 
    # CDN container TTL (if container is public)
    attr_reader :cdn_ttl
 
    # CDN container URL (if container if public)
    attr_reader :cdn_url
    
    # The parent CloudFiles::Connection object for this container
    attr_reader :connection
 
    # Retrieves an existing CloudFiles::Container object tied to the current CloudFiles::Connection.  If the requested
    # container does not exist, it will raise a NoSuchContainerException.  
    # 
    # Will likely not be called directly, instead use connection.container('container_name') to retrieve the object.
    def initialize(connection,name)
      @connection = connection
      @name = name
      @storagehost = self.connection.storagehost
      @storagepath = self.connection.storagepath+"/"+@name
      @cdnmgmthost = self.connection.cdnmgmthost
      @cdnmgmtpath = self.connection.cdnmgmtpath+"/"+@name
      populate
    end
 
    # Retrieves data about the container and populates class variables.  It is automatically called
    # when the Container class is instantiated.  If you need to refresh the variables, such as 
    # size, count, cdn_enabled, cdn_ttl, and cdn_url, this method can be called again.
    #
    #   container.count
    #   => 2
    #   [Upload new file to the container]
    #   container.count
    #   => 2
    #   container.populate
    #   container.count
    #   => 3
    def populate
      # Get the size and object count
      response = self.connection.cfreq("HEAD",@storagehost,@storagepath+"/")
      raise NoSuchContainerException, "Container #{@name} does not exist" unless (response.code == "204")
      @bytes = response["x-container-bytes-used"].to_i
      @count = response["x-container-object-count"].to_i
 
      # Get the CDN-related details
      response = self.connection.cfreq("HEAD",@cdnmgmthost,@cdnmgmtpath)
      if (response.code == "204")
        @cdn_enabled = true
        @cdn_ttl = response["x-ttl"]
        @cdn_url = response["x-cdn-uri"]
      else
        @cdn_enabled = false
        @cdn_ttl = false
        @cdn_url = false
      end
      true
    end
    alias :refresh :populate
 
    # Returns the CloudFiles::StorageObject for the named object.  Refer to the CloudFiles::StorageObject class for available
    # methods.  If the object exists, it will be returned.  If the object does not exist, a NoSuchObjectException will be thrown.
    # 
    #   object = container.object('test.txt')
    #   object.data
    #   => "This is test data"
    #
    #   object = container.object('newfile.txt')
    #   => NoSuchObjectException: Object newfile.txt does not exist
    def object(objectname)
      o = CloudFiles::StorageObject.new(self,objectname,true)
      return o
    end
    alias :get_object :object
    
 
    # Gathers a list of all available objects in the current container and returns an array of object names.  
    #   container = cf.container("My Container")
    #   container.objects                     #=> [ "dog", "cat", "donkey", "monkeydir/capuchin"]
    # Pass a limit argument to limit the list to a number of objects:
    #   container.objects(:limit => 1)                  #=> [ "dog" ]
    # Pass an offset with or without a limit to start the list at a certain object:
    #   container.objects(:limit => 1, :offset => 2)                #=> [ "donkey" ]
    # Pass a prefix to search for objects that start with a certain string:
    #   container.objects(:prefix => "do")       #=> [ "dog", "donkey" ]
    # Only search within a certain pseudo-filesystem path:
    #   container.objects(:path => 'monkeydir')     #=> ["monkeydir/capuchin"]
    # All arguments to this method are optional.
    # 
    # Returns an empty array if no object exist in the container.  Throws an InvalidResponseException
    # if the request fails.
    def objects(params = {})
      paramarr = []
      paramarr << ["limit=#{URI.encode(params[:limit].to_i)}"] if params[:limit]
      paramarr << ["offset=#{URI.encode(params[:offset].to_i)}"] if params[:offset]
      paramarr << ["prefix=#{URI.encode(params[:prefix])}"] if params[:prefix]
      paramarr << ["path=#{URI.encode(params[:path])}"] if params[:path]
      paramstr = (paramarr.size > 0)? paramarr.join("&") : "" ;
      response = self.connection.cfreq("GET",@storagehost,"#{@storagepath}?#{paramstr}")
      return [] if (response.code == "204")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "200")
      return response.body.to_a.map { |x| x.chomp }
    end
    alias :list_objects :objects
 
    # Retrieves a list of all objects in the current container along with their size in bytes, hash, and content_type.
    # If no objects exist, an empty hash is returned.  Throws an InvalidResponseException if the request fails.  Takes a
    # parameter hash as an argument, in the same form as the objects method.
    # 
    # Returns a hash in the same format as the containers_detail from the CloudFiles class.
    #
    #   container.objects_detail
    #   => {"test.txt"=>{:content_type=>"application/octet-stream", 
    #                    :hash=>"e2a6fcb4771aa3509f6b27b6a97da55b", 
    #                    :last_modified=>Mon Jan 19 10:43:36 -0600 2009, 
    #                    :bytes=>"16"}, 
    #       "new.txt"=>{:content_type=>"application/octet-stream", 
    #                   :hash=>"0aa820d91aed05d2ef291d324e47bc96", 
    #                   :last_modified=>Wed Jan 28 10:16:26 -0600 2009, 
    #                   :bytes=>"22"}
    #      }
    def objects_detail(params = {})
      paramarr = []
      paramarr << ["format=xml"]
      paramarr << ["limit=#{URI.encode(params[:limit].to_i)}"] if params[:limit]
      paramarr << ["offset=#{URI.encode(params[:offset].to_i)}"] if params[:offset]
      paramarr << ["prefix=#{URI.encode(params[:prefix])}"] if params[:prefix]
      paramarr << ["path=#{URI.encode(params[:path])}"] if params[:path]
      paramstr = (paramarr.size > 0)? paramarr.join("&") : "" ;
      response = self.connection.cfreq("GET",@storagehost,"#{@storagepath}?#{paramstr}")
      return {} if (response.code == "204")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "200")
      doc = REXML::Document.new(response.body)
      detailhash = {}
      doc.elements.each("container/object") { |o|
        detailhash[o.elements["name"].text] = { :bytes => o.elements["bytes"].text, :hash => o.elements["hash"].text, :content_type => o.elements["content_type"].text, :last_modified => Time.parse(o.elements["last_modified"].text) }
      }
      doc = nil
      return detailhash
    end
    alias :list_objects_info :objects_detail
 
    # Returns true if the container is public and CDN-enabled.  Returns false otherwise.
    #
    #   public_container.public?
    #   => true
    #
    #   private_container.public?
    #   => false
    def public?
      return @cdn_enabled
    end
 
    # Returns true if a container is empty and returns false otherwise.
    #
    #   new_container.empty?
    #   => true
    #
    #   full_container.empty?
    #   => false
    def empty?
      return (@count.to_i == 0)? true : false
    end
 
    # Returns true if object exists and returns false otherwise.
    #
    #   container.object_exists?('goodfile.txt')
    #   => true
    #
    #   container.object_exists?('badfile.txt')
    #   => false
    def object_exists?(objectname)
      response = self.connection.cfreq("HEAD",@storagehost,"#{@storagepath}/#{objectname}")
      return (response.code == "204")? true : false
    end
 
    # Creates a new CloudFiles::StorageObject in the current container. 
    #
    # If an object with the specified name exists in the current container, that object will be returned.  Otherwise,
    # an empty new object will be returned.
    #
    # Passing in the optional make_path argument as true will create zero-byte objects to simulate a filesystem path
    # to the object, if an objectname with path separators ("/path/to/myfile.mp3") is supplied.  These path objects can 
    # be used in the Container.objects method.
    def create_object(objectname,make_path = false)
      CloudFiles::StorageObject.new(self,objectname,false,make_path)
    end
    
    # Removes an CloudFiles::StorageObject from a container.  True is returned if the removal is successful.  Throws 
    # NoSuchObjectException if the object doesn't exist.  Throws InvalidResponseException if the request fails.
    #
    #   container.delete_object('new.txt')
    #   => true
    #
    #   container.delete_object('nonexistent_file.txt')
    #   => NoSuchObjectException: Object nonexistent_file.txt does not exist
    def delete_object(objectname)
      response = self.connection.cfreq("DELETE",@storagehost,"#{@storagepath}/#{objectname}")
      raise NoSuchObjectException, "Object #{objectname} does not exist" if (response.code == "404")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "204")
      true
    end
 
    # Makes a container publicly available via the Cloud Files CDN and returns true upon success.  Throws NoSuchContainerException
    # if the container doesn't exist or if the request fails.
    # 
    # Takes an optional argument, which is the CDN cache TTL in seconds (default 86400 seconds or 1 day)
    #
    #   container.make_public(432000)
    #   => true
    def make_public(ttl = 86400)
      headers = { "X-CDN-Enabled" => "True", "X-TTL" => ttl.to_s }
      response = self.connection.cfreq("PUT",@cdnmgmthost,@cdnmgmtpath,headers)
      raise NoSuchContainerException, "Container #{@name} does not exist" unless (response.code == "201" || response.code == "202")
      true
    end
 
    # Makes a container private and returns true upon success.  Throws NoSuchContainerException
    # if the container doesn't exist or if the request fails.
    #
    # Note that if the container was previously public, it will continue to exist out on the CDN until it expires.
    #
    #   container.make_private
    #   => true
    def make_private
      headers = { "X-CDN-Enabled" => "False" }
      response = self.connection.cfreq("PUT",@cdnmgmthost,@cdnmgmtpath,headers)
      raise NoSuchContainerException, "Container #{@name} does not exist" unless (response.code == "201" || response.code == "202")
      true
    end
    
    def to_s # :nodoc:
      @name
    end
 
  end
 
end