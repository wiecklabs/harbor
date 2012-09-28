require_relative 'helper'
require 'fileutils'

class ReloaderTest < MiniTest::Unit::TestCase
  class ::ReloadingApp
    def self.root
      (Pathname(__FILE__).dirname + "tmp/reloading_app").expand_path
    end
  end

  def setup
    Harbor.stubs(:registered_applications => [::ReloadingApp])
    FileUtils.rm_rf ReloadingApp.root
    FileUtils.cp_r (Pathname(__FILE__).dirname + "fixtures/reloading_app").expand_path, ::ReloadingApp.root.parent
    FileUtils.mkdir ReloadingApp.root + 'helpers' unless Dir.exist? ReloadingApp.root + 'helpers'

    @reloader = Harbor::Reloader.new
    @reloader.populate_files
  end

  def teardown
    Harbor::Dispatcher::clear_event_handlers!
    Harbor::Router::instance.clear!
    Dir[::ReloadingApp.root.to_s + "/**/*.rb"].each do |file|
      $LOADED_FEATURES.delete file
    end
    ::ReloadingApp.instance_eval do
      remove_const :Models if const_defined? :Models
      remove_const :Forms if const_defined? :Forms
      remove_const :Controllers if const_defined? :Controllers
      remove_const :Helpers if const_defined? :Helpers
    end
  end

  def change_code(file, pattern, replace)
    code = File.read(file)
    code.gsub!(pattern, replace)
    File.open(file, "w") { |f| f.write(code) }
    File.stubs(:mtime => Time.now + 10)
  end

  def test_reload_models_that_were_changed
    sample_model_path = ::ReloadingApp.root + 'models/sample_model.rb'
    require sample_model_path

    refute ::ReloadingApp::Models::SampleModel::instance_methods.include?(:new_find)

    @reloader.reload!
    change_code(sample_model_path, 'find', 'new_find')
    @reloader.reload!

    assert ::ReloadingApp::Models::SampleModel::instance_methods.include?(:new_find)
  end

  def test_reload_forms_that_were_changed
    sample_form_path = ::ReloadingApp.root + 'forms/sample_form.rb'
    require sample_form_path

    refute ::ReloadingApp::Forms::SampleForm::instance_methods.include?(:new_validate)

    @reloader.reload!
    change_code(sample_form_path, 'validate', 'new_validate')
    @reloader.reload!

    assert ::ReloadingApp::Forms::SampleForm::instance_methods.include?(:new_validate)
  end

  def test_performs_reloading_when_request_begins
    @reloader.expects(:perform)
    @reloader.enable!
    Harbor::Dispatcher::instance.raise_event(:begin_request, "request began!")
  end

  def test_respects_cooldown_time
    sample_form_path = ::ReloadingApp.root + 'forms/sample_form.rb'
    require sample_form_path

    @reloader.perform
    change_code(sample_form_path, 'validate', 'new_validate')
    @reloader.cooldown = 10
    Time.warp(9) do
      @reloader.perform
    end

    refute ::ReloadingApp::Forms::SampleForm::instance_methods.include?(:new_validate)
  end

  def test_loads_new_controllers
    new_controller_path = ::ReloadingApp.root + 'controllers/new_controller.rb'

    File.open(new_controller_path, "w") do |f|
      f.write <<-CONTROLLER
        class ReloadingApp
          module Controllers
            class NewController < Harbor::Controller
            end
          end
        end
      CONTROLLER
    end
    @reloader.reload!

    assert ReloadingApp.const_defined? :Controllers
    assert ReloadingApp::Controllers.const_defined? :NewController
  end

  def test_redefines_controller_constants_when_reloaded
    sample_controller_path = ReloadingApp.root + 'controllers/sample_controller.rb'

    @reloader.reload!
    an_instance = ReloadingApp::Controllers::SampleController.new
    File.stubs(:mtime => Time.now + 10)
    @reloader.reload!

    refute an_instance.class == ReloadingApp::Controllers::SampleController
  end

  def test_loads_and_register_new_helpers
    new_helper_path = ::ReloadingApp.root + 'helpers/new_helper.rb'

    File.open(new_helper_path, "w") do |f|
      f.write <<-HELPER
        class ReloadingApp
          module Helpers
            module NewHelper
            end
          end
        end
      HELPER
    end
    config.helpers.expects(:register)
    @reloader.reload!
  end
end
