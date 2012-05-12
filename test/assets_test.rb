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
    @assets.append_path "#{path}/javascripts"
    @assets.append_path "#{path}/stylesheets"
  end

  def create_request(path)
    request = Harbor::Test::Request.new
    request.env['PATH_INFO'] = path
    request
  end

  def test_cascades_self_when_compiling_is_enabled
    @cascade.expects(:<<).with(@assets)
    @assets.compile = true
  end

  def test_does_not_match_if_compiling_is_disabled
    @assets.compile = false
    refute @assets.match(create_request('assets/application.js'))
  end

  def test_matches_assets_if_compiling_is_enabled
    assert @assets.match(create_request('assets/application.js'))
    assert @assets.match(create_request('assets/application.css'))
  end

  def test_return_nil_if_no_match_is_found
    refute @assets.match(create_request('assets/whatever.css'))
  end

  def test_delegates_call_to_sprockets_env_with_updated_path_info
    response = Harbor::Test::Response.new

    Harbor::Dispatcher::RackWrapper.expects(:call).
      with(@assets.sprockets_env, has_entry('PATH_INFO' => 'application.js'), response)

    @assets.call(create_request('assets/application.js'), response)
  end
end
