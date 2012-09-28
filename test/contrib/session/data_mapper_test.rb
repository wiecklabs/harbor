require "pathname"
require Pathname(__FILE__).dirname + "../../helper"
require "harbor/contrib/session/data_mapper"

require "dm-migrations"
DataMapper.setup :default, "sqlite3::memory:"
DataMapper.finalize

module Contrib
  module Session
    class DataMapperTest < Test::Unit::TestCase

      CookieRequest = Class.new(Harbor::Test::Request) do
        def cookies
          @cookies ||= {}
        end
      end

      def setup
        Harbor::Session.options[:store] = Harbor::Contrib::Session::DataMapper
        DataMapper.auto_migrate!
      end

      def teardown
        Harbor::Session.options[:store] = Harbor::Session::Cookie
      end

      def test_loading_fresh_session_creates_record
        session = Harbor::Session.new(Harbor::Test::Request.new)
        
        assert_equal 1, ::Session.all.size
        assert_equal ::Session.first.id, session[:session_id]
      end

      def test_session_is_found_by_uuid
        session = ::Session.create
        request = CookieRequest.new
        request.cookies["harbor.session"] = session.id

        request_session = Harbor::Session.new(request)

        assert_equal 1, ::Session.all.size
        assert_equal session.id, request_session[:session_id]
      end

      def test_session_data_is_loaded
        session = ::Session.create(:data => { :user_id => 4 })
        request = CookieRequest.new
        request.cookies["harbor.session"] = session.id

        request_session = Harbor::Session.new(request)
        assert_equal 4, request_session[:user_id]
      end

      def test_commit_session
        session = Harbor::Session.new(Harbor::Test::Request.new)
        session[:user_id] = 10
        cookie = session.save
        instance = ::Session.first
        assert_equal instance.id, cookie[:value]
        assert_equal instance.data, { :user_id => 10 }
      end

      def test_expiring_sessions
        Harbor::Session.options[:expire_after] = 10
        session = ::Session.create(:data => { :user_id => 10 })

        Time.warp(20) do
          request = CookieRequest.new
          request.cookies["harbor.session"] = session.id

          request_session = Harbor::Session.new(request)

          assert_equal 2, ::Session.all.size
          assert_equal nil, request_session[:user_id]
        end
      ensure
        Harbor::Session.options[:expire_after] = nil
      end

    end
  end
end