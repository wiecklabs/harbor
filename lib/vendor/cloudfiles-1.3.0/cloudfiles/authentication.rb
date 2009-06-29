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
  class Authentication
    
    # Performs an authentication to the Cloud Files servers.  Opens a new HTTP connection to the API server,
    # sends the credentials, and looks for a successful authentication.  If it succeeds, it sets the cdmmgmthost,
    # cdmmgmtpath, storagehost, storagepath, authtoken, and authok variables on the connection.  If it fails, it raises
    # an AuthenticationException.
    #
    # Should probably never be called directly.
    def initialize(connection)
      path = '/auth'
      hdrhash = { "X-Auth-User" => connection.authuser, "X-Auth-Key" => connection.authkey }
      begin
        server = Net::HTTP.new('api.mosso.com',443)
        server.use_ssl = true
        server.verify_mode = OpenSSL::SSL::VERIFY_NONE
        server.start
      rescue
        raise ConnectionException, "Unable to connect to #{server}"
      end
      response = server.get(path,hdrhash)
      if (response.code == "204")
        connection.cdnmgmthost = URI.parse(response["x-cdn-management-url"]).host
        connection.cdnmgmtpath = URI.parse(response["x-cdn-management-url"]).path
        connection.storagehost = URI.parse(response["x-storage-url"]).host
        connection.storagepath = URI.parse(response["x-storage-url"]).path
        connection.authtoken = response["x-auth-token"]
        connection.authok = true
      else
        connection.authtoken = false
        raise AuthenticationException, "Authentication failed"
      end
      server.finish
    end
  end
end