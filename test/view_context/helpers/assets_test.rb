require_relative "../../helper"

module ViewContext
  module Helpers
    class AssetsTest < MiniTest::Unit::TestCase
      def setup
        @helper = Class.new{ include Harbor::ViewContext::Helpers::Assets }.new
        @helper.stubs(:compile_assets? => false)
      end

      def test_renders_javascript_tag_with_full_url
        url = 'http://foo.bar/application.js'
        assert_equal "<script type=\"text/javascript\" src=\"#{url}\"></script>", @helper.javascript(url)
      end

      def test_appends_js_extension_for_application_scripts
        assert @helper.javascript('my').include? '"/my.js"'
      end

      def test_renders_multiple_scripts
        tags = @helper.javascript('my', 'other')
        assert tags.include? '"/my.js"'
        assert tags.include? '"/other.js"'
      end

      def test_expands_assets_with_body_if_compilation_is_enabled
        assets = ['required-asset.js', 'asset.js']
        @helper.stubs(:asset_path).with('required-asset.js').returns('required-asset.js')
        @helper.stubs(:asset_path).with('asset.js').returns('asset.js')
        @helper.stubs(compile_assets?: true, asset_for: assets)

        tags = @helper.javascript('asset')

        assert tags.include? '"required-asset.js?body=1"'
        assert tags.include? '"asset.js?body=1"'
      end

      def test_renders_precompiled_assets
        @helper.stubs(asset_for: 'single-asset-digest-stuff.js')
        tags = @helper.javascript('single-asset')
        assert tags.include? '"/assets/single-asset-digest-stuff.js"'
      end

      def test_renders_stylesheet_tag_with_full_url
        url = 'http://foo.bar/application.css'
        assert_equal "<link href=\"#{url}\" rel=\"stylesheet\" type=\"text/css\"/>", @helper.stylesheet(url)
      end

      def test_appends_css_extension_for_application_scripts
        assert @helper.stylesheet('my').include? '"/my.css"'
      end

      def test_renders_multiple_scripts
        tags = @helper.stylesheet('my', 'other')
        assert tags.include? '"/my.css"'
        assert tags.include? '"/other.css"'
      end

      def test_expands_assets_with_body_if_compilation_is_enabled
        assets = ['required-asset.css', 'asset.css']
        @helper.stubs(:asset_path).with('required-asset.css').returns('required-asset.css')
        @helper.stubs(:asset_path).with('asset.css').returns('asset.css')
        @helper.stubs(compile_assets?: true, asset_for: assets)

        tags = @helper.stylesheet('asset')

        assert tags.include? '"required-asset.css?body=1"'
        assert tags.include? '"asset.css?body=1"'
      end

      def test_renders_precompiled_assets
        @helper.stubs(asset_for: 'single-asset-digest-stuff.css')
        tags = @helper.stylesheet('single-asset')
        assert tags.include? '"/assets/single-asset-digest-stuff.css"'
      end
    end
  end
end
