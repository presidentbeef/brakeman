require_relative '../test'
require 'brakeman/rescanner'

class OjSettingsTests < Minitest::Test
  include BrakemanTester::RescanTestHelper

  def setup
    @oj_config = "config/initializers/oj.rb"
  end

  def test_oj_mimic_json
    before_rescan_of @oj_config, "rails5.2" do
      replace @oj_config, "# Oj.mimic_JSON", "Oj.mimic_JSON"
    end

    assert_fixed 1 # Fix default Oj.load() behavior
    assert_new 0
  end

  def test_oj_default_setting
    before_rescan_of @oj_config, "rails5.2" do
      replace @oj_config, "# Oj.default_options", "Oj.default_options"
    end

    assert_fixed 1 # Fix default Oj.load() behavior
    assert_new 0
  end

  def test_oj_default_setting_still_unsafe
    before_rescan_of @oj_config, "rails5.2" do
      append @oj_config, "Oj.default_options = { whatever: false }"
    end

    assert_fixed 0 # Default is still bad, no changes 
    assert_new 0
  end
end
