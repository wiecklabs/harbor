require_relative 'helper'

class ViewContextTest < MiniTest::Unit::TestCase

  def setup
    Harbor::View.paths << Pathname(__FILE__).dirname + "fixtures/views/view_context"
    @assertor = Class.new do
      include MiniTest::Assertions
    end.new

    @context = {}
    @context[:assertor] = @assertor

    Harbor::View::plugins("sample/plugin").clear
  end

  def teardown
    Harbor::View.paths.clear
  end

  def test_instance_variables_are_available_in_context
    @context[:variable] = true
    @context[:assertions] = lambda do
      @assertor.assert !!defined?(@variable), "Variable not provided"
      @assertor.assert_equal true, @variable
    end

    Harbor::View.new("assertions", @context).to_s
  end

  def test_render_passes_variables_on
    @context[:assertions] = lambda do
      if defined?(@in_render)
        @assertor.assert @in_render, "render did not pass its values to the new view"
      else
        render "assertions", :in_render => true
      end
    end

    Harbor::View.new("assertions", @context).to_s
  end

  def test_render_within_render
    @context[:variable] = true
    @context[:assertions] = lambda do
      case
      when @render_2
        @assertor.assert @variable, "@variable was #{@variable.inspect} in second render"
      when @render_1
        @assertor.assert @variable, "@variable was #{@variable.inspect} before second render"

        render "assertions", :render_2 => true, :variable => @variable

        @assertor.assert @variable, "@variable was #{@variable.inspect} after second render"
      else
        render "assertions", :render_1 => true
        @assertor.assert @variable, "@variable was #{@variable.inspect} after renders"
      end
    end

    Harbor::View.new("assertions", @context).to_s
  end

  def test_plugin_returns_empty_array_when_no_plugins_registered
    @context[:assertions] = lambda do
      @assertor.assert_equal([], plugin("some/plugin/that/doesn/exist/#{Time.now.usec}"))
    end

    Harbor::View.new("assertions", @context).to_s
  end

  def test_plugin_returns_all_rendered_plugins
    Harbor::View::plugins("sample/plugin") << "Plugin1"
    Harbor::View::plugins("sample/plugin") << "Plugin2"

    @context[:assertions] = lambda do
      @assertor.assert_equal("Plugin1Plugin2", plugin("sample/plugin").join)
    end

    Harbor::View.new("assertions", @context).to_s
  end

  def test_plugin_returns_an_array
    Harbor::View::plugins("sample/plugin") << "Plugin1"
    Harbor::View::plugins("sample/plugin") << "Plugin2"

    @context[:assertions] = lambda do
      @assertor.assert_kind_of(Array, plugin("sample/plugin"))
    end

    Harbor::View.new("assertions", @context).to_s
  end

end
