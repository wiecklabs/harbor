require "pathname"
require Pathname(__FILE__).dirname + "helper"

include Rack::Utils

describe "Rack::Utils #parse_query" do
  it "should parse a normal query" do
    parse_query("user=John").should == { "user" => "John" }
  end

  it "should parse a blank query" do
    parse_query("").should == {}
  end

  it "should parse a nil query" do
    parse_query(nil).should == {}
  end

  it "should parse a query that starts with &" do
    parse_query('&message=sample+message').should == { 'message' => 'sample message' }
  end

  it "should parse a nested query" do
    parse_query("user[name]=John").should == { "user" => { "name" => "John" } }
  end

  it "should parse a deep nested query" do
    params_hash = { "id" => "1", "user" => { "contact" => { "email" => { "address" => "test" } } } }
    parse_query("id=1&user[contact][email][address]=test").should == params_hash
  end

  it "should parse a query with an array" do
    parse_query("users[]=1&users[]=2").should == { "users" => ["1", "2"] }
  end

  it "should parse an arbitrarily complex query" do
    params_hash = { "user" => { "name" => "John", "email" => { "addresses" => ["one@aol.com", "two@aol.com"] } } }
    parse_query("user[name]=John&user[email][addresses][]=one@aol.com&user[email][addresses][]=two@aol.com").should == params_hash
  end
end

describe "Rack::Utils::Multipart #self.parse_multipart" do
  before(:all) do
    @filename = "volcanoUPI_800x531.jpg"
    @request_params = Multipart.parse_multipart(upload(@filename).env)
  end
  
  it "should parse a deep nested query" do
    @request_params["video"].has_key?("transcoder").should == true 
  end
end