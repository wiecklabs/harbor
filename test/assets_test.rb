require_relative 'helper'

class AssetsTest < MiniTest::Unit::TestCase
  def setup
    @cascade = mock
    @cascade.stubs(:<<)
    @cascade.stubs(:unregister)

    @assets = Harbor::Assets.new
    @assets.stubs(:cascade => @cascade)

    @assets.compile = true

    path = Pathname(__FILE__).dirname + "fixtures/assets_files"
    @assets.paths << "#{path}/javascripts"
    @assets.paths << "#{path}/stylesheets"
  end

  def stub_request(path)
    stub(:path_info => path)
  end

  def test_cascades_self_if_serve_static
    @cascade.expects(:<<).with(@assets)
    @assets.compile = true
  end

  def test_does_not_match_if_compiling_is_disabled
    @assets.compile = false
    refute @assets.match(stub_request('assets/application.js'))
  end

  def test_matches_assets_if_compiling_is_enabled
    assert @assets.match(stub_request('assets/application.js'))
    assert @assets.match(stub_request('assets/application.css'))
  end

  def test_return_nil_if_no_match_is_found
    refute @assets.match(stub_request('assets/whatever.css'))
  end

  def test_delegates_call_to_sprockets_env
    flunk("To implement")
  end
end
