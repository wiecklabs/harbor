require_relative 'helper'

class ResponseTest < MiniTest::Unit::TestCase

  def setup
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"
    Harbor::View::layouts.default("layouts/application")
    @request = Harbor::Test::Request.new
    @response = Harbor::Response.new(@request)
  end

  def teardown
    Harbor::View::path.clear
    Harbor::View::layouts.clear
  end

  def test_content_buffer
    @response.puts "Hello World"
    @response.print("Hello World\n")
    assert_equal((["Hello World\n"] * 2).join, @response.buffer)
  end

  def test_default_status
    assert_equal(200, @response.status)
  end

  def test_default_content_type
    assert_equal("text/html", @response.content_type)
  end

  def test_set_cookie_with_hash
    cookie_expires_on = Time.now
    expires_gmt_string = cookie_expires_on.gmtime.strftime("%a, %d-%b-%Y %H:%M:%S GMT")

    assert_raises(ArgumentError) { @response.set_cookie(nil, { :value => '1234', :domain => 'www.example.com', :path => '/test', :expires => cookie_expires_on}) }
    assert_raises(ArgumentError) { @response.set_cookie('', { :value => '1234', :domain => 'www.example.com', :path => '/test', :expires => cookie_expires_on}) }

    @response.set_cookie('session_id', { :value => '', :domain => 'www.example.com', :path => '/test', :expires => cookie_expires_on})
    assert_equal("session_id=; domain=www.example.com; path=/test; expires=#{expires_gmt_string}", @response['Set-Cookie'])
    @response['Set-Cookie'] = nil

    @response.set_cookie('session_id', { :value => '1234', :path => '/test', :expires => cookie_expires_on})
    assert_equal("session_id=1234; path=/test; expires=#{expires_gmt_string}", @response['Set-Cookie'])
    @response['Set-Cookie'] = nil

    @response.set_cookie('session_id', { :value => '1234' })
    assert_equal("session_id=1234", @response['Set-Cookie'])
    @response['Set-Cookie'] = nil

    @response.set_cookie('session_id', { :value => '1234', :domain => 'www.example.com', :path => '/test', :expires => cookie_expires_on})
    assert_equal("session_id=1234; domain=www.example.com; path=/test; expires=#{expires_gmt_string}", @response['Set-Cookie'])
    @response['Set-Cookie'] = nil

    @response.set_cookie('session_id', { :http_only => true, :value => '1234', :domain => 'www.example.com', :path => '/test', :expires => cookie_expires_on})
    assert_equal("session_id=1234; domain=www.example.com; path=/test; expires=#{expires_gmt_string}; HTTPOnly=", @response['Set-Cookie'])
    @response['Set-Cookie'] = nil
  end

  def test_set_cookie_get_path_when_not_specified_and_expiring
    cookie_expires_on = Time.now
    expires_gmt_string = cookie_expires_on.gmtime.strftime("%a, %d-%b-%Y %H:%M:%S GMT")

    @response.set_cookie('session_id', { :value => '', :domain => 'www.example.com', :expires => cookie_expires_on})
    assert_equal("session_id=; domain=www.example.com; path=/; expires=#{expires_gmt_string}", @response['Set-Cookie'])
    @response['Set-Cookie'] = nil
  end

  def test_delete_cookie
    @response.delete_cookie('session_id')
    assert_equal(["session_id=; path=/; expires=Thu, 01-Jan-1970 00:00:00 GMT"], @response['Set-Cookie'])
    @response['Set-Cookie'] = nil
  end

  def test_standard_headers
    @response.print "Hello World"
    assert_equal({ "Content-Type" => "text/html", "Content-Length" => "Hello World".size.to_s }, @response.headers)
  end

  def test_render_html_view_with_layout
    @response.render "index", :text => "test"
    assert_equal("LAYOUT\ntest\n", @response.buffer)
  end

  def test_render_xml
    @response.render Harbor::XMLView.new("list")
    assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>Bob</name>\n</site>\n", @response.buffer)
    assert_equal("text/xml", @response.content_type)
  end

  def test_deprecated_multiple_layout_behavior
    result = capture_stderr do
      @response.render "index", :text => "test", :layout => ["layouts/application", "layouts/other"]
    end

    assert_equal("LAYOUT\ntest\n", @response.buffer)
    assert_match /deprecated/, result
  end

  def test_errors_is_a_errors_collection
    assert_kind_of(Harbor::Errors, @response.errors)
  end

  ##
  # STREAM_FILE / SEND_FILE
  ##

  def test_stream_file_with_string_io
    @response.stream_file(StringIO.new("test"))

    assert_equal "4", @response.headers["Content-Length"]
    assert_equal "application/octet-stream", @response.headers["Content-Type"]
  end

  def test_stream_file_with_io
    file = File.open(__FILE__)
    @response.stream_file(file)

    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "application/octet-stream", @response.headers["Content-Type"]
  ensure
    file.close
  end

  def test_stream_file_with_filename
    @response.stream_file(__FILE__)

    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  def test_stream_file_with_pathname
    @response.stream_file(Pathname(__FILE__))

    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  def test_stream_file_with_harbor_file
    store = Harbor::FileStore::Local.new(File.dirname(__FILE__))
    file = store.get(File.basename(__FILE__))

    @response.stream_file(file)
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  ##
  # STREAM_FILE / SEND_FILE with X-Sendfile enabled
  ##

  def test_stream_file_with_string_io_and_x_sendfile
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Sendfile"
    @response.stream_file(StringIO.new("test"))

    assert !@response.headers["X-Sendfile"]
    assert_equal "4", @response.headers["Content-Length"]
    assert_equal "application/octet-stream", @response.headers["Content-Type"]
  end

  def test_stream_file_with_io_and_x_sendfile
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Sendfile"
    file = File.open(__FILE__)
    @response.stream_file(file)

    assert !@response.headers["X-Sendfile"]
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "application/octet-stream", @response.headers["Content-Type"]
  ensure
    file.close
  end

  ##
  # Apache X-Sendfile Tests
  ##
  def test_apache_stream_file_with_filename_and_x_sendfile
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Sendfile"
    @response.stream_file(__FILE__)

    assert_equal __FILE__, @response.headers["X-Sendfile"]
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  def test_apache_stream_file_with_pathname_and_x_sendfile
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Sendfile"
    @response.stream_file(Pathname(__FILE__))

    assert_equal Pathname(__FILE__).expand_path.to_s, @response.headers["X-Sendfile"]
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  def test_apache_stream_file_with_harbor_file_and_x_sendfile
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Sendfile"
    store = Harbor::FileStore::Local.new(File.dirname(__FILE__))
    file = store.get(File.basename(__FILE__))

    @response.stream_file(file)

    assert_equal __FILE__, @response.headers["X-Sendfile"]
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  ##
  # nginx X-Sendfile tests NOT using X-Accel-Mapping
  ##
  def test_nginx_stream_file_with_filename_and_x_sendfile
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Accel-Redirect"
    @response.stream_file(__FILE__)

    assert_equal __FILE__, @response.headers["X-Accel-Redirect"]
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  def test_nginx_stream_file_with_pathname_and_x_sendfile
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Accel-Redirect"
    @response.stream_file(Pathname(__FILE__))

    assert_equal Pathname(__FILE__).expand_path.to_s, @response.headers["X-Accel-Redirect"]
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  def test_nginx_stream_file_with_harbor_file_and_x_sendfile
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Accel-Redirect"
    store = Harbor::FileStore::Local.new(File.dirname(__FILE__))
    file = store.get(File.basename(__FILE__))

    @response.stream_file(file)

    assert_equal __FILE__, @response.headers["X-Accel-Redirect"]
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  ##
  # nginx X-Sendfile tests using X-Accel-Mapping
  ##
  def test_nginx_stream_file_with_filename_and_x_sendfile_with_mapping
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Accel-Redirect"
    @request.env["HTTP_X_ACCEL_MAPPING"] = "#{Pathname(__FILE__).dirname}=/some/other/path"

    @response.stream_file(__FILE__)

    assert_equal File.join("/some/other/path", File.basename(__FILE__)), @response.headers["X-Accel-Redirect"]
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  def test_nginx_stream_file_with_pathname_and_x_sendfile_with_mapping
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Accel-Redirect"
    @request.env["HTTP_X_ACCEL_MAPPING"] = "#{Pathname(__FILE__).dirname}=/some/other/path"

    @response.stream_file(Pathname(__FILE__))

    assert_equal "/some/other/path/#{File.basename(__FILE__)}", @response.headers["X-Accel-Redirect"]
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  def test_nginx_stream_file_with_harbor_file_and_x_sendfile_with_mapping
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Accel-Redirect"
    @request.env["HTTP_X_ACCEL_MAPPING"] = "#{Pathname(__FILE__).dirname}=/some/other/path"

    store = Harbor::FileStore::Local.new(File.dirname(__FILE__))
    file = store.get(File.basename(__FILE__))

    @response.stream_file(file)

    assert_equal "/some/other/path/#{File.basename(__FILE__)}", @response.headers["X-Accel-Redirect"]
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  ##
  # nginx ModZip tests
  ##

  def test_nginx_mod_zip_send_files_has_properly_formatted_body
    @request.env["HTTP_MOD_ZIP_ENABLED"] = "True"

    file = Harbor::File.new(Pathname(__FILE__))
    file.name = "My Custom Filename.rb"

    @response.send_files("test.zip", [file])

    assert_equal "#{Zlib.crc32(File.read(file.path)).to_s(16)} #{File.size(file.path)} #{File.expand_path(file.path)} #{file.name}\n", @response.buffer

    assert_equal "zip", @response.headers["X-Archive-Files"]
    assert_equal "attachment; filename=\"test.zip\"", @response.headers["Content-Disposition"]
    assert_equal "application/zip", @response.headers["Content-Type"]
  end

  def test_nginx_mod_zip_send_files_has_properly_formatted_body_for_non_standard_file_objects
    @request.env["HTTP_MOD_ZIP_ENABLED"] = "True"

    file = Class.new do
      attr_accessor :path, :name
      def initialize(path, name)
        @path = path
        @name = name
      end
    end.new(Pathname(__FILE__), "My Custom Filename.rb")

    @response.send_files("test.zip", [file])

    assert_equal "#{Zlib.crc32(File.read(file.path)).to_s(16)} #{File.size(file.path)} #{File.expand_path(file.path)} #{file.name}\n", @response.buffer

    assert_equal "zip", @response.headers["X-Archive-Files"]
    assert_equal "attachment; filename=\"test.zip\"", @response.headers["Content-Disposition"]
    assert_equal "application/zip", @response.headers["Content-Type"]
  end

  def test_nginx_mod_zip_has_appropriate_header
    @request.env["HTTP_MOD_ZIP_ENABLED"] = "True"

    file = Harbor::File.new(Pathname(__FILE__))

    @response.send_files("test", [file])

    assert_equal "zip", @response.headers["X-Archive-Files"]
  end

  ##
  # CACHE
  ##

  def test_cache_requires_block
    assert_raises(ArgumentError) { @response.cache(nil, Time.now) }
  end

  def test_cache_sets_last_modified_header
    assert !@response.headers["Last-Modified"]
    modified = Time.now
    @response.cache(nil, modified) {}
    assert @response.headers["Last-Modified"]
    assert_equal modified.httpdate, @response.headers["Last-Modified"]
  end

  def test_cache_returns_304_with_matching_if_modified_since_request_header
    time = Time.now
    request = Harbor::Test::Request.new
    request.env["HTTP_IF_MODIFIED_SINCE"] = time.httpdate
    response = Harbor::Response.new(request)

    called = false
    assert_throws(:abort_request) do
      response.cache(nil, time) { called = true }
    end
    assert_equal 304, response.status
    assert !called
  end

  def test_cache_yields_with_no_if_modified_since_header
    request = Harbor::Test::Request.new
    response = Harbor::Response.new(request)

    called = false
    response.cache(nil, Time.now) { called = true }
    assert called
  end

  def test_cache_yields_with_recent_updated_at
    request = Harbor::Test::Request.new
    request.env["HTTP_IF_MODIFIED_SINCE"] = Time.now.httpdate
    response = Harbor::Response.new(request)

    called = false
    Time.warp(10) do
      response.cache(nil, Time.now) { called = true }
    end
    assert called
  end

  def test_cache_raises_argument_error_with_no_cache_configured
    assert_raises(ArgumentError) do
      @response.cache("key", Time.now, 10) {}
    end
  end

  def test_cache_with_ttl_sets_cache_control_without_store
    @response.cache(nil, Time.now, 10) { |response| response.puts "Test" }

    assert_equal "max-age=10, must-revalidate", @response.headers["Cache-Control"]
  end

  def test_cache_with_ttl_sets_cache_control_with_store
    with_cache do |cache|
      @response.cache("key", Time.now, 10) { |response| response.puts "Test" }

      assert_equal "max-age=10, must-revalidate", @response.headers["Cache-Control"]
    end
  end

  def test_cache_miss_writes_to_cache_store_with_ttl
    with_cache do |cache|
      @response.cache("key", Time.now, 10) { |response| response.puts "Test" }

      item = cache.get("page-key")

      assert item
      assert_equal "Test\n", item.content
    end
  end

  def test_cache_hit_with_ttl_returns_no_content
    with_cache do |cache|
      time = Time.now
      request = Harbor::Test::Request.new
      request.env["HTTP_IF_MODIFIED_SINCE"] = time.httpdate
      response = Harbor::Response.new(request)
      response.cache("key", time, 10) {}

      assert_throws(:abort_request) do
        response.cache("key", time, 10) {}
      end
      assert_equal 304, response.status
    end
  end

  def test_cache_miss_with_modified_since_but_expired_ttl
    with_cache do |cache|
      time = Time.now
      request = Harbor::Test::Request.new
      request.env["HTTP_IF_MODIFIED_SINCE"] = time.httpdate
      response = Harbor::Response.new(request)
      response.cache("key", time, 10) {}

      Time.warp(20) do
        response.cache("key", time, 10) {}
      end
    end
  end

  def test_content_type_header_deleted_with_204
    response = Harbor::Test::Response.new
    request = Harbor::Test::Request.new
    response.request = request

    response.status = 204

    assert_nil response.headers["Content-Type"]
    assert_nil response.headers["Content-Length"]
  end

  def test_content_type_header_deleted_with_304
    response = Harbor::Test::Response.new
    request = Harbor::Test::Request.new
    response.request = request

    response.status = 304

    assert_nil response.headers["Content-Type"]
    assert_nil response.headers["Content-Length"]
  end

  ##
  # Messages
  ##

  def test_redirect_without_session
    response = Harbor::Test::Response.new
    request = Harbor::Test::Request.new
    response.request = request

    response.message("error", "Error")
    response.redirect("/redirect", {})
    assert_equal "/redirect?messages%5Berror%5D=Error", response.headers["Location"]
  end

  def test_redirect_with_session
    response = Harbor::Test::Response.new
    request = Harbor::Test::Request.new
    request.session = Harbor::Test::Session.new
    response.request = request

    response.message("error", "Error")
    response.redirect("/redirect", {})
    assert_equal "/redirect", response.headers["Location"]
  end

  def test_redirect_with_encoded_url_and_params
    response = Harbor::Test::Response.new
    request = Harbor::Test::Request.new
    response.request = request

    response.message("error", "Error")
    response.redirect("/redirect?key=Stuff", {})
    location = response.headers["Location"]
    root, query = location.split(/\?/).sort
    assert_equal "/redirect", root
    assert_equal [ "key=Stuff", "messages%5Berror%5D=Error" ].sort, query.split(/\&/).sort
  end

  private

  def with_cache
    cache = Harbor::Cache.new(Harbor::Cache::Memory.new)
    Harbor::View.cache = cache
    yield cache
  ensure
    cache.delete_matching(/.*/)
    Harbor::View.cache = nil
  end

end
