require_relative "helper"

class ControllerPathNormalizationTest < MiniTest::Unit::TestCase

  module Controllers
    class Animals
    end
  end

  module Admin
    class Animals
    end
  end

  def test_controllers_namespace_is_excluded_from_normalized_path
    refute_match /controllers/, Harbor::Controller::NormalizedPath.new(Controllers::Animals, ":id").to_s
  end

  def test_admin_namespace_is_not_excluded_from_normalized_path
    assert_equal "controller_path_normalization_test/admin/animals/:id", Harbor::Controller::NormalizedPath.new(Admin::Animals, ":id").to_s
  end

  def test_paths_are_made_relative_to_controller
    assert_equal "controller_path_normalization_test/animals/:id", Harbor::Controller::NormalizedPath.new(Controllers::Animals, ":id").to_s
  end

  def test_absolute_paths_are_not_made_relatve_to_controller
    assert_equal "all_about_goats", Harbor::Controller::NormalizedPath.new(Controllers::Animals, "/all_about_goats").to_s
  end

end
