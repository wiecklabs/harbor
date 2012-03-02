require_relative "helper"

class FormHelperTest < MiniTest::Unit::TestCase
  def test_basic_form
    form = <<-HTML
<form action="/users" method="post">
  <input type="submit">
</form>
    HTML
    assert_equal(form, evaluate(<<-ERB))
<% form "/users" do %>
  <input type="submit">
<% end %>
    ERB
  end

  def test_form_with_alternative_method
    form = <<-HTML
<form action="/users" method="post">
  <input type="hidden" name="_method" value="put">
  <input type="submit">
</form>
    HTML
    assert_equal(form, evaluate(<<-ERB))
<% form "/users", :method => :put do %>
  <input type="submit">
<% end %>
    ERB
  end

  def test_form_with_inferred_enctype
    form = <<-HTML
<form action="/users" method="post" enctype="multipart/form-data">
  <input type="file">
  <input type="submit">
</form>
    HTML
    assert_equal(form, evaluate(<<-ERB))
<% form "/users", :method => :post do %>
  <input type="file">
  <input type="submit">
<% end %>
    ERB
  end

  def test_form_with_forced_enctype
    form = <<-HTML
<form action="/users" method="post" enctype="application/x-www-form-urlencoded">
  <input type="file">
  <input type="submit">
</form>
    HTML
    assert_equal(form, evaluate(<<-ERB))
<% form "/users", :method => :post, :enctype => "application/x-www-form-urlencoded" do %>
  <input type="file">
  <input type="submit">
<% end %>
    ERB
  end

  def test_form_with_extra_options
    form = <<-HTML
<form action="/users" method="post" class="form">
  this is eval'd
  <input type="submit">
</form>
    HTML
    assert_equal(form, evaluate(<<-ERB))
<% form "/users", :method => :post, :class => "form" do %>
  <%= "this is eval'd" %>
  <input type="submit">
<% end %>
    ERB
  end

  def test_form_with_content_before_it
    form = <<-HTML
Content
<form action="/users" method="post" class="form">
  this is eval'd
  <input type="submit">
</form>
    HTML
    assert_equal(form, evaluate(<<-ERB))
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
