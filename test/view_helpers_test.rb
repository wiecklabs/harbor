require_relative "helper"

class ViewHelpersTest < MiniTest::Unit::TestCase
  class ::HelpersApplication; end
  class ::ApplicationWithNoHelpers; end
  class ::ApplicationWithOtherConstants
    module Helpers
      SOME_CONSTANT = 'foo'
      class Bar; end
    end
  end

  def setup
    @view_helpers = Harbor::ViewHelpers.new
    @view_helpers.paths << Pathname(__FILE__).dirname + "fixtures/helpers/*.rb"

    $LOADED_FEATURES.delete File.expand_path(Pathname(__FILE__).dirname + "fixtures/helpers/sample_helper.rb")
    HelpersApplication.instance_eval { remove_const :Helpers if const_defined? :Helpers }
  end

  def test_registers_all_known_applications_view_helpers
    Harbor.stubs(:registered_applications => [HelpersApplication])
    @view_helpers.register_all!
    assert Harbor::ViewContext.include? HelpersApplication::Helpers::SampleHelper
  end

  def test_do_not_throw_exception_if_applications_helper_module_doesnt_exist
    Harbor.stubs(:registered_applications => [ApplicationWithNoHelpers])
    @view_helpers.register_all!
  end

  def test_do_not_try_to_register_non_module_constants
    Harbor.stubs(:registered_applications => [ApplicationWithOtherConstants])
    @view_helpers.register_all!
  end
end
