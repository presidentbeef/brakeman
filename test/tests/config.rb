require_relative '../test'

class RailsConfiguration < Minitest::Test
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

    # Rails 6.0 settings should not be included
    assert_nil tracker.config.rails[:action_dispatch][:use_cookies_with_metadata]
  end
end
