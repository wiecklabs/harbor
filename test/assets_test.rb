require_relative 'helper'

class AssetsTest < MiniTest::Unit::TestCase
  def setup
    @cascade = mock
    @cascade.stubs(:<<)
    @cascade.stubs(:unregister)

    @assets = Harbor::Assets.new(@cascade)

    path = Pathname(__FILE__).dirname + "fixtures/assets_files"
    @assets.paths << "#{path}/app_1"
    @assets.paths << "#{path}/app_2"
  end

  def stub_request(path)
    stub(:path_info => path)
  end

  def test_cascades_self_if_serve_static
    @cascade.expects(:<<).with(@assets)
    @assets.serve_static = true
  end

  def test_does_not_match_if_not_enabled_to_serve_static
    refute @assets.match(stub_request('assets/public-file'))
  end

  def test_matches_static_assets
    @assets.serve_static = true
    assert @assets.match(stub_request('assets/public-file'))
  end

  def test_searches_on_multiple_paths
    @assets.serve_static = true
    assert @assets.match(stub_request('assets/public-file-2'))
  end

  def test_return_nil_if_no_match_is_found
    @assets.serve_static = true
    refute @assets.match(stub_request('assets/public-file-3'))
  end

  def test_caches_and_stream_file
    response = mock
    response.expects(:cache).yields(response)
    response.expects(:stream_file)

    @assets.call(stub_request('public-file'), response)
  end
end
