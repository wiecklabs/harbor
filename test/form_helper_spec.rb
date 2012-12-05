#!/usr/bin/env jruby

require_relative "helper"

describe "Form Helpers" do
  it "must generate a default form" do
    form = <<-HTML
<form action="/users" method="post">
  <input type="submit">
</form>
    HTML
    evaluate(<<-ERB).must_equal form
<% form "/users" do %>
  <input type="submit">
<% end %>
    ERB
  end

  it "must use alternative HTTP-method" do
    form = <<-HTML
<form action="/users" method="post">
  <input type="hidden" name="_method" value="put">
  <input type="submit">
</form>
    HTML
    evaluate(<<-ERB).must_equal form
<% form "/users", :method => :put do %>
  <input type="submit">
<% end %>
    ERB
  end

  it "must use inferred enctype" do
    form = <<-HTML
<form action="/users" method="post" enctype="multipart/form-data">
  <input type="file">
  <input type="submit">
</form>
    HTML
    evaluate(<<-ERB).must_equal form
<% form "/users", :method => :post do %>
  <input type="file">
  <input type="submit">
<% end %>
    ERB
  end

  it "must use forced enctype" do
    form = <<-HTML
<form action="/users" method="post" enctype="application/x-www-form-urlencoded">
  <input type="file">
  <input type="submit">
</form>
    HTML
    evaluate(<<-ERB).must_equal form
<% form "/users", :method => :post, :enctype => "application/x-www-form-urlencoded" do %>
  <input type="file">
  <input type="submit">
<% end %>
    ERB
  end

  it "must accept extra options" do
    form = <<-HTML
<form action="/users" method="post" class="form">
  this is eval'd
  <input type="submit">
</form>
    HTML
    evaluate(<<-ERB).must_equal form
<% form "/users", :method => :post, :class => "form" do %>
  <%= "this is eval'd" %>
  <input type="submit">
<% end %>
    ERB
  end

  it "must render with content before it" do
    form = <<-HTML
Content
<form action="/users" method="post" class="form">
  this is eval'd
  <input type="submit">
</form>
    HTML
    evaluate(<<-ERB).must_equal form
Content
<% form "/users", :method => :post, :class => "form" do %>
  <%= "this is eval'd" %>
  <input type="submit">
<% end %>
    ERB
  end

  def evaluate(erubis_data)
    Erubis::FastEruby.new(erubis_data).evaluate(Harbor::ViewContext.new(nil, {}))
  end
end