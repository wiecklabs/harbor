require_relative "helper"

class AssetsRouterTest < MiniTest::Unit::TestCase
  def setup
    @router = Harbor::AssetsRouter.new
    assets = Pathname(__FILE__).dirname + "assets_files"
    @assets_config = stub(
      :paths => ["#{assets}/app_1", "#{assets}/app_2"],
      :serve_static => true
    )
    @router.stubs(:config => stub(:assets => @assets_config))
  end

  def stub_request(path)
    stub(:path_info => path)
  end

  def test_does_not_match_if_not_enabled_to_serve_static
    @assets_config.stubs(:serve_static => false)
    refute @router.match(stub_request('public-file'))
  end

  def test_return_an_asset_instance_if_request_matches
    request = stub_request('public-file')
    assert_kind_of Harbor::AssetsRouter::Asset, @router.match(request)
  end

  def test_searches_on_multiple_paths
    refute_nil @router.match(stub_request('public-file-2'))
  end

  def test_return_nil_if_no_match_is_found
    request = stub_request('public-file-3')
    refute @router.match(request)
  end
end
