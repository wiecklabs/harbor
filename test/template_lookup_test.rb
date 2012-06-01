require_relative 'helper'

class TemplateLookupTest < MiniTest::Unit::TestCase
  def setup
    @collection = Harbor::TemplateLookup.new
    @collection.paths.unshift Pathname(__FILE__).dirname + "fixtures/views"
    Tilt.stubs(:mappings => {'erb' => nil, 'str' => nil, 'jsonify' => nil})
  end

  def test_finds_on_known_paths
    assert @collection.find("index.html.erb")
    assert_raises(RuntimeError) { @collection.find('somefilethatdoesnotexist.html.erb') }
  end

  def test_empty_paths
    @collection.paths.clear
    assert_raises(RuntimeError) { @collection.find("index.html.erb") }
  end

  def test_supports_multiple_engines
    assert @collection.find('index_str').last =~ /\.str$/
  end

  def test_finds_based_on_format
    result = @collection.find('index', 'json')
    assert_equal 'json', result.first
    assert result.last =~ /\.jsonify$/
  end
end
