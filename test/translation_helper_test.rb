require "pathname"
require Pathname(__FILE__).dirname + "helper"

class TranslationHelperTest < Test::Unit::TestCase

  class TranslationHelper
    include Harbor::ViewContext::Helpers::Translation
  end

  def setup
    @helper = TranslationHelper.new
  end

  def test_non_existant_translation
    assert_equal(nil, @helper.t(nil, nil))
  end

end

