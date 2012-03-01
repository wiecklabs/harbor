require_relative 'helper'

class RackUtilsTest < MiniTest::Unit::TestCase

  include Rack::Utils

  def test_parsing_a_normal_query
    assert_equal({ "user" => "John" }, parse_nested_query("user=John"))
  end

  def test_parsing_a_blank_query
    assert_equal({}, parse_nested_query(""))
  end

  def test_parsing_a_nil_query
    assert_equal({}, parse_nested_query(nil))
  end

  def test_parsing_a_query_that_starts_with_ampersand
    assert_equal({ 'message' => 'sample message' }, parse_nested_query('&message=sample+message'))
  end

  def test_parsing_a_nested_query
    assert_equal({ "user" => { "name" => "John" } }, parse_nested_query("user[name]=John"))
  end

  def test_parsing_a_deep_nested_query
    params_hash = { "id" => "1", "user" => { "contact" => { "email" => { "address" => "test" } } } }
    assert_equal(params_hash, parse_nested_query("id=1&user[contact][email][address]=test"))
  end

  def test_parsing_a_query_with_an_array
    assert_equal({ "users" => ["1", "2"] }, parse_nested_query("users[]=1&users[]=2"))
  end

  def test_parsing_and_arbitrarily_complex_query
    params_hash = { "user" => { "name" => "John", "email" => { "addresses" => ["one@aol.com", "two@aol.com"] } } }
    assert_equal(params_hash, parse_nested_query("user[name]=John&user[email][addresses][]=one@aol.com&user[email][addresses][]=two@aol.com"))
  end

  def test_parsing_a_deep_multipart_nested_query
    filename = "volcanoUPI_800x531.jpg"
    request_params = Multipart.parse_multipart(upload(filename).env)

    assert(request_params["video"].has_key?("transcoder"))
  end
end
