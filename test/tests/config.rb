require_relative '../test'
require 'brakeman/rescanner'

class RailsConfiguration < Minitest::Test
  include BrakemanTester::RescanTestHelper

  def test_rails5_2_configuration_load_defaults
    tracker = Brakeman.run(File.join(TEST_PATH, "apps", "rails5.2"))

    refute tracker.config.rails.empty?

    # Settings like `config.load_defaults(5.2)` shold be included, not
    # just settings like `config.some.attribute = ...`
    assert_equal Sexp.new(:lit, 5.2), tracker.config.rails[:load_defaults]

    # Rails 5.0 settings should be included
    assert_equal Sexp.new(:true), tracker.config.rails[:action_controller][:per_form_csrf_tokens]

    # Rails 5.1 settings should be included
    assert_equal Sexp.new(:false), tracker.config.rails[:assets][:unknown_asset_fallback]

    # Rails 5.2 settings should be included
    assert_equal Sexp.new(:true), tracker.config.rails[:active_record][:belongs_to_required_by_default]
    assert_equal Sexp.new(:true), tracker.config.rails[:action_controller][:default_protect_from_forgery]

    # Rails 6.0 settings should not be included
    assert_nil tracker.config.rails[:action_dispatch][:use_cookies_with_metadata]
  end

  def test_rails5_2_configuration_load_defaults_with_config
    before_rescan_of ["config/application.rb", "config/environments/production.rb"], "rails5.2" do
      replace "config/application.rb", "# config.action_controller.per_form_csrf_tokens = true", "config.action_controller.per_form_csrf_tokens = false"
      replace "config/environments/production.rb", "# config.action_controller.default_protect_from_forgery = true", "config.action_controller.default_protect_from_forgery = false"
    end

    tracker = @rescanner.tracker

    refute tracker.config.rails.empty?

    # Local Rails 5.0 overwrite should be used
    assert_equal Sexp.new(:false), tracker.config.rails[:action_controller][:per_form_csrf_tokens]

    # Local Rails 5.2 overwrite should be used
    assert_equal Sexp.new(:false), tracker.config.rails[:action_controller][:default_protect_from_forgery]
  end

  def test_rails7_configuration_load_defaults
    tracker = Brakeman.run(File.join(TEST_PATH, "apps", "rails7"))

    assert_equal Sexp.new(:str, '7.0'), tracker.config.rails[:load_defaults]

    # Check a 6.1 config
    assert_equal Sexp.new(:true), tracker.config.rails[:action_controller][:urlsafe_csrf_tokens]

    # Check a 7.0 config
    assert_equal Sexp.new(:true), tracker.config.rails[:action_controller][:wrap_parameters_by_default]
  end

  def test_invalid_load_defaults
    tracker = BrakemanTester.new_tracker
    tracker.config.rails[:load_defaults] = Sexp.new(:str, 'asd2ojasdo.asodja1')
    config = Brakeman::Config.new(tracker)
    config.load_rails_defaults

    # Defaults are not loaded
    assert_nil config.rails.dig(:ssl_options, :hsts, :subdomains)
  end
end
