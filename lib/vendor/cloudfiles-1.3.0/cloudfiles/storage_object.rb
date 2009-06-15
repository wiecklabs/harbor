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
  class StorageObject
    
    # Name of the object corresponding to the instantiated object
    attr_reader :name
 
    # Size of the object (in bytes)
    attr_reader :bytes
    
    # The parent CloudFiles::Container object
    attr_reader :container
 
    # Date of the object's last modification
    attr_reader :last_modified
 
    # ETag of the object data
    attr_reader :etag
 
    # Content type of the object data
    attr_reader :content_type
 
    # Builds a new CloudFiles::StorageObject in the current container.  If force_exist is set, the object must exist or a
    # NoSuchObjectException will be raised.  If not, an "empty" CloudFiles::StorageObject will be returned, ready for data
    # via CloudFiles::StorageObject.write
    def initialize(container,objectname,force_exists=false,make_path=false) 
      if objectname.match(/\?/)
        raise SyntaxException, "Object #{objectname} contains an invalid character in the name (? not allowed)"
      end
      @container = container
      @containername = container.name
      @name = objectname
      @make_path = make_path
      @storagehost = self.container.connection.storagehost
      @storagepath = self.container.connection.storagepath+"/#{@containername}/#{@name}"
      if container.object_exists?(objectname)
        populate
      else
        raise NoSuchObjectException, "Object #{@name} does not exist" if force_exists
      end
    end
    
    # Caches data about the CloudFiles::StorageObject for fast retrieval.  This method is automatically called when the 
    # class is initialized, but it can be called again if the data needs to be updated.
    def populate
      response = self.container.connection.cfreq("HEAD",@storagehost,@storagepath)
      raise NoSuchObjectException, "Object #{@name} does not exist" if (response.code != "204")
      @bytes = response["content-length"]
      @last_modified = Time.parse(response["last-modified"])
      @etag = response["etag"]
      @content_type = response["content-type"]
      resphash = {}
      response.to_hash.select { |k,v| k.match(/^x-object-meta/) }.each { |x| resphash[x[0]] = x[1][0].to_s }
      @metadata = resphash
      true
    end
    alias :refresh :populate
 
    # Retrieves the data from an object and stores the data in memory.  The data is returned as a string.
    # Throws a NoSuchObjectException if the object doesn't exist.
    #
    # If the optional size and range arguments are provided, the call will return the number of bytes provided by
    # size, starting from the offset provided in offset.
    # 
    #   object.data
    #   => "This is the text stored in the file"
    def data(size=-1,offset=0,headers = {})
      if size.to_i > 0
        range = sprintf("bytes=%d-%d", offset.to_i, (offset.to_i + size.to_i) - 1)
        headers['Range'] = range
      end
      response = self.container.connection.cfreq("GET",@storagehost,@storagepath,headers)
      raise NoSuchObjectException, "Object #{@name} does not exist" unless (response.code =~ /^20/)
      response.body.chomp
    end
 
    # Retrieves the data from an object and returns a stream that must be passed to a block.  Throws a 
    # NoSuchObjectException if the object doesn't exist.
    #
    # If the optional size and range arguments are provided, the call will return the number of bytes provided by
    # size, starting from the offset provided in offset.
    #
    #   data = ""
    #   object.data_stream do |chunk|
    #     data += chunk
    #   end
    #  
    #   data
    #   => "This is the text stored in the file"
    def data_stream(size=-1,offset=0,headers = {},&block)
      if size.to_i > 0
        range = sprintf("bytes=%d-%d", offset.to_i, (offset.to_i + size.to_i) - 1)
        headers['Range'] = range
      end
      self.container.connection.cfreq("GET",@storagehost,@storagepath,headers,nil) do |response|
        raise NoSuchObjectException, "Object #{@name} does not exist" unless (response.code == "200")
        response.read_body(&block)
      end
    end
 
    # Returns the object's metadata as a nicely formatted hash, stripping off the X-Meta-Object- prefix that the system prepends to the
    # key name.
    #
    #    object.metadata
    #    => {"ruby"=>"cool", "foo"=>"bar"}
    def metadata
      metahash = {}
      @metadata.each{|key, value| metahash[key.gsub(/x-object-meta-/,'').gsub(/\+\-/, ' ')] = URI.decode(value).gsub(/\+\-/, ' ')}
      metahash
    end
    
    # Sets the metadata for an object.  By passing a hash as an argument, you can set the metadata for an object.
    # However, setting metadata will overwrite any existing metadata for the object.
    # 
    # Throws NoSuchObjectException if the object doesn't exist.  Throws InvalidResponseException if the request
    # fails.
    def set_metadata(metadatahash)
      headers = {}
      metadatahash.each{|key, value| headers['X-Object-Meta-' + key.to_s.capitalize] = value.to_s}
      response = self.container.connection.cfreq("POST",@storagehost,@storagepath,headers)
      raise NoSuchObjectException, "Object #{@name} does not exist" if (response.code == "404")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "202")
      true
    end
    
    # Takes supplied data and writes it to the object, saving it.  You can supply an optional hash of headers, including
    # Content-Type and ETag, that will be applied to the object.
    #
    # If you would rather stream the data in chunks, instead of reading it all into memory at once, you can pass an 
    # IO object for the data, such as: object.write(open('/path/to/file.mp3'))
    #
    # You can compute your own MD5 sum and send it in the "ETag" header.  If you provide yours, it will be compared to
    # the MD5 sum on the server side.  If they do not match, the server will return a 422 status code and a MisMatchedChecksumException
    # will be raised.  If you do not provide an MD5 sum as the ETag, one will be computed on the server side.
    #
    # Updates the container cache and returns true on success, raises exceptions if stuff breaks.
    #
    #   object = container.create_object("newfile.txt")
    #
    #   object.write("This is new data")
    #   => true
    #
    #   object.data
    #   => "This is new data"
    def write(data=nil,headers={})
      #raise SyntaxException, "No data was provided for object '#{@name}'" if (data.nil?)
      # Try to get the content type
      raise SyntaxException, "No data or header updates supplied" if (data.nil? and headers.empty?)
      if headers['Content-Type'].nil?
        type = MIME::Types.type_for(self.name).first.to_s
        if type.empty?
          headers['Content-Type'] = "application/octet-stream"
        else
          headers['Content-Type'] = type
        end
      end
      response = self.container.connection.cfreq("PUT",@storagehost,"#{@storagepath}",headers,data)
      raise InvalidResponseException, "Invalid content-length header sent" if (response.code == "412")
      raise MisMatchedChecksumException, "Mismatched etag" if (response.code == "422")
      raise InvalidResponseException, "Invalid response code #{response.code}" unless (response.code == "201")
      make_path(File.dirname(self.name)) if @make_path == true
      self.populate
      true
    end
    
    # A convenience method to stream data into an object from a local file (or anything that can be loaded by Ruby's open method)
    #
    # Throws an Errno::ENOENT if the file cannot be read.
    #
    #   object.data
    #   => "This is my data"
    #
    #   object.load_from_filename("/tmp/file.txt")
    #   => true
    #
    #   object.data
    #   => "This data was in the file /tmp/file.txt"
    #
    #   object.load_from_filename("/tmp/nonexistent.txt")
    #   => Errno::ENOENT: No such file or directory - /tmp/nonexistent.txt
    def load_from_filename(filename)
      f = open(filename)
      self.write(f)
      f.close
      true
    end
 
    # A convenience method to stream data from an object into a local file
    #
    # Throws an Errno::ENOENT if the file cannot be opened for writing due to a path error, 
    # and Errno::EACCES if the file cannot be opened for writing due to permissions.
    #
    #   object.data
    #   => "This is my data"
    #
    #   object.save_to_filename("/tmp/file.txt")
    #   => true
    #
    #   $ cat /tmp/file.txt
    #   "This is my data"
    #
    #   object.save_to_filename("/tmp/owned_by_root.txt")
    #   => Errno::EACCES: Permission denied - /tmp/owned_by_root.txt
    def save_to_filename(filename)
      File.open(filename, 'w+') do |f|
        self.data_stream do |chunk|
          f.write chunk
        end
      end
      true
    end
    
    # If the parent container is public (CDN-enabled), returns the CDN URL to this object.  Otherwise, return nil
    #
    #   public_object.public_url
    #   => "http://cdn.cloudfiles.mosso.com/c10181/rampage.jpg"
    #
    #   private_object.public_url
    #   => nil
    def public_url
      self.container.public? ? self.container.cdn_url + "/#{URI.encode(@name)}" : nil
    end
    
    def to_s # :nodoc:
      @name
    end
    
    private
    
    def make_path(path) # :nodoc:
      if path == "." || path == "/"
        return
      else
        unless self.container.object_exists?(path)
          o = self.container.create_object(path)
          o.write(nil,{'Content-Type' => 'application/directory'})
        end
        make_path(File.dirname(path))
      end
    end
 
  end
 
end