require_relative "../helper"

module AssetsRouter
  class AssetTest < MiniTest::Unit::TestCase
    class Response
      attr_reader :cache_args, :streamed_file

      def cache(key, last_modified, ttl)
        @cache_args = {key: key, last_modified: last_modified, max_age: ttl}
        yield
      end

      def cached?
        not @cache_args.nil?
      end

      def stream_file(file)
        @streamed_file = file
      end
    end

    def setup
      @file_path = 'some/file/path'
      @file_mtime = Time.now
      @one_day = 60 * 60 * 24

      File.stubs(:mtime => @file_mtime)
      @asset = Harbor::AssetsRouter::Asset.new(@file_path)
      @response = Response.new

      @asset.serve(@response)
    end

    def test_caches_and_stream_file
      assert @response.cached?
      assert_equal @file_path, @response.streamed_file
    end

    def test_does_not_use_cache_store
      refute @response.cache_args[:key]
    end

    def test_uses_file_mtime_for_last_modified_header
      assert_equal @file_mtime, @response.cache_args[:last_modified]
    end

    def test_sets_cache_control_max_age_to_one_day
      assert_equal @one_day, @response.cache_args[:max_age]
    end
  end
end
