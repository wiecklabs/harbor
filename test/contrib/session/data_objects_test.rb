require "pathname"
require Pathname(__FILE__).dirname + "../../helper"

require "do_sqlite3"
require "harbor/contrib/session/data_objects"

module Contrib
  module Session
    class DataObjectsTest < Test::Unit::TestCase

      CookieRequest = Class.new(Harbor::Test::Request) do
        def cookies
          @cookies ||= {}
        end
      end

      def setup        
        Harbor::Session.configure do |session|
          session[:store] = Harbor::Contrib::Session::DataObjects
          session[:connection_uri] = 'sqlite3::memory:'
        end
      end

      def teardown
        if Harbor::Contrib::Session::DataObjects.session_table_exists?
          Harbor::Contrib::Session::DataObjects.execute('DROP TABLE sessions')
        end
      
        Harbor::Contrib::Session::DataObjects.instance_eval do
          @table_exists = nil
        end
      
        Harbor::Session.configure do |session|
          session[:store] = Harbor::Session::Cookie
          session.delete(:connection_uri)
        end
      end
      
      def test_creating_session_table
        assert ! Harbor::Contrib::Session::DataObjects.session_table_exists?
        
        Harbor::Contrib::Session::DataObjects.create_session_table
        
        assert Harbor::Contrib::Session::DataObjects.session_table_exists?
      end
      
      def test_creates_session_table_if_not_exists
        # just hit the code for creating the table
        Harbor::Session.new(Harbor::Test::Request.new)
        
        assert Harbor::Contrib::Session::DataObjects.session_table_exists?
      end

      def test_loading_fresh_session_creates_record
        session = Harbor::Session.new(Harbor::Test::Request.new)
        session_from_db = get_raw_session(session[:session_id])
        
        assert_equal 1, session_records_count
        assert_equal session_from_db[:session_id], session[:session_id]
      end

      def test_session_is_found_by_uuid
        Harbor::Contrib::Session::DataObjects.create_session_table
      
        session = create_session
        request = CookieRequest.new
        request.cookies["harbor.session"] = session[:session_id]

        request_session = Harbor::Session.new(request)

        assert_equal 1, session_records_count
        assert_equal session[:session_id], request_session[:session_id]
      end

      def test_session_data_is_loaded
        Harbor::Contrib::Session::DataObjects.create_session_table
      
        session = create_session({ :user_id => 4 })
        
        request = CookieRequest.new
        request.cookies["harbor.session"] = session[:session_id]

        request_session = Harbor::Session.new(request)
        assert_equal 4, request_session[:user_id]
      end

      def test_commit_session
        session = Harbor::Session.new(Harbor::Test::Request.new)
        session[:value] = 10
        
        cookie = session.save
        
        session_from_db = get_raw_session(session[:session_id])
        
        expected_data = Harbor::Contrib::Session::DataObjects.dump({ :value => 10 })
        
        assert_equal expected_data, session_from_db[:data]
        assert_equal cookie[:value], session_from_db[:session_id]
      end
      
      def test_cant_assign_session_id
        session = Harbor::Session.new(Harbor::Test::Request.new)
        
        assert_raise ArgumentError do session[:session_id] = 'whatever'; end
      end
      
      def test_session_timeout
        Harbor::Session.options[:expire_after] = timeout = 20
        
        Harbor::Contrib::Session::DataObjects.create_session_table
        
        value = 5
        session = create_session({ :value => value })        
        request = CookieRequest.new
        request.cookies["harbor.session"] = session[:session_id]
        
        time_elapsed = timeout-10
        assert_session_valid_and_save(time_elapsed, request, value, value+1)
        
        time_elapsed += timeout-10
        assert_session_valid_and_save(time_elapsed, request, value+1, value+2)

        time_elapsed += timeout+1
        assert_session_expired(time_elapsed, request)
      ensure
        Harbor::Session.options[:expire_after] = nil
      end
      
      def test_user_id_is_not_lazy_parsed
        Harbor::Contrib::Session::DataObjects.create_session_table
        
        session = create_session({ :user_id => 4 })        
        request = CookieRequest.new
        request.cookies["harbor.session"] = session[:session_id]
        
        request_session = Harbor::Session.new(request)
        
        assert request_session.data.instance_variable_get(:@data).nil?
        
        request_session[:user_id]
        
        assert request_session.data.instance_variable_get(:@data).nil?
      end
      
      def test_data_is_lazy_parsed
        Harbor::Contrib::Session::DataObjects.create_session_table
        
        session = create_session({ :other => 4 })        
        request = CookieRequest.new
        request.cookies["harbor.session"] = session[:session_id]
        
        request_session = Harbor::Session.new(request)
        
        assert request_session.data.instance_variable_get(:@data).nil?
        
        # Parses data
        request_session[:other]
        
        assert ! request_session.data.instance_variable_get(:@data).nil?
      end

    protected
      def assert_session_valid_and_save(time_elapsed, request, value, new_value)
        Time.warp(time_elapsed) do
          request_session = Harbor::Session.new(request)
        
          assert_equal 1, session_records_count
          assert_equal value, request_session[:value]
          
          request_session[:value] = new_value
          
          request_session.save
        end
      end
      
      def assert_session_expired(time_elapsed, request)
        Time.warp(time_elapsed) do
          request_session = Harbor::Session.new(request)

          assert_equal 2, session_records_count
          assert_equal nil, request_session[:user_id]
        end
      end
    
      def get_raw_session(cookie, updated_at=nil)
        Harbor::Contrib::Session::DataObjects.get_raw_session(cookie, updated_at)
      end
      
      def create_session(data = {})
        Harbor::Contrib::Session::DataObjects.create_session(data)
      end
      
      def session_records_count
        count = 0
      
        Harbor::Contrib::Session::DataObjects.with_connection do |connection|
          cmd = connection.create_command("SELECT COUNT(id) FROM sessions;")        
          reader = cmd.execute_reader        
          if reader.next! then count = reader.values[0] end
          reader.close
        end
                
        count
      end
    end
  end
end
