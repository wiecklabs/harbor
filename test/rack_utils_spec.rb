#!/usr/bin/env jruby

require_relative "helper"

describe Rack::Utils do

  include Rack::Utils

  it "must parse a normal query" do
    parse_nested_query("user=John").must_equal "user" => "John"
  end

  it "must parse a blank query" do
    parse_nested_query("").must_equal({})
  end

  it "must parse a nil query" do
    parse_nested_query(nil).must_equal({})
  end

  it "must parse a query that starts with an ampersand" do
    parse_nested_query('&message=sample+message').must_equal "message" => "sample message"
  end

  it "must parse a nested query" do
    parse_nested_query("user[name]=John").must_equal({ "user" => { "name" => "John" } })
  end

  it "must parse a deeply nested query" do
    params_hash = { "id" => "1", "user" => { "contact" => { "email" => { "address" => "test" } } } }

    parse_nested_query("id=1&user[contact][email][address]=test").must_equal params_hash
  end

  it "must parse a query with an array" do
    parse_nested_query("users[]=1&users[]=2").must_equal({ "users" => ["1", "2"] })
  end

  it "must parse an arbitrarily complex query" do
    parse_nested_query("user[name]=John&user[email][addresses][]=one@aol.com&user[email][addresses][]=two@aol.com")
      .must_equal({ "user" => { "name" => "John", "email" => { "addresses" => ["one@aol.com", "two@aol.com"] } } })
  end

  it "must parse a deep multipart nested query" do
    Rack::Utils::Multipart.parse_multipart(
        Helper::upload("volcanoUPI_800x531.jpg").env
    )["video"].must_include "transcoder"
  end
end