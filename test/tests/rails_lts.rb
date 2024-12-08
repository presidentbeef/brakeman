require_relative '../test'
require 'brakeman/rescanner'

class RailsLTSTests < Minitest::Test
  include BrakemanTester::RescanTestHelper

  def test_gemfile_lock_rails_lts
    gemfile = "Gemfile.lock"

    before_rescan_of gemfile, "rails_with_xss_plugin" do
      append gemfile, "railslts-version (2.3.18.6)"
    end

    assert @rescanner.tracker.config.gem_version(:'railslts-version'), "2.3.18.6"
    assert_new 0
    assert_fixed 2
  end

  def test_rails_lts_CVE_2012_1099
    gemfile = "Gemfile.lock"

    before_rescan_of gemfile, "rails_with_xss_plugin" do
      append gemfile, "railslts-version (2.3.18.7)"
    end

    assert @rescanner.tracker.config.gem_version(:'railslts-version'), "2.3.18.7"
    assert_new 0
    assert_fixed 3 # 2 + CVE-2012-1099
  end

  def test_rails_lts_CVE_2014_0081
    gemfile = "Gemfile.lock"

    before_rescan_of gemfile, "rails_with_xss_plugin" do
      append gemfile, "railslts-version (2.3.18.8)"
    end

    assert @rescanner.tracker.config.gem_version(:'railslts-version'), "2.3.18.8"
    assert_new 0
    assert_fixed 4 # 2 + CVE-2012-1099 + CVE_2014_0081
  end

  def test_rails_lts_CVE_2014_0130
    gemfile = "Gemfile.lock"

    before_rescan_of gemfile, "rails_with_xss_plugin" do
      append gemfile, "railslts-version (2.3.18.9)"
    end

    assert @rescanner.tracker.config.gem_version(:'railslts-version'), "2.3.18.9"
    assert_new 0
    assert_fixed 5
  end
end
