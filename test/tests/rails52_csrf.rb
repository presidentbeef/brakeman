require_relative '../test'
require 'brakeman/rescanner'

class Rails52CSRFTest < Minitest::Test
  include BrakemanTester::RescanTestHelper
  include BrakemanTester::FindWarning

  def report
    @report
  end

  def test_csrf_with_no_load_defaults
    tracker = nil

    # Terribly abusing the rescan functionality here.
    # Actually don't want the rescan, just want to run a regular scan
    # because we don't have the capability to rescan with on config changes
    # like this and I don't feel like building it right now.
    before_rescan_of ['config/application.rb'], 'rails5.2' do |app_dir|
      replace 'config/application.rb', 'config.load_defaults 5.2', ''
      tracker = Brakeman.run(app_path: app_dir, parallel_checks: false)
    end

    @report = tracker.report.to_hash

    assert_warning check_name: "ForgerySetting",
      type: :controller,
      warning_code: 7,
      fingerprint: "6f5239fb87c64764d0c209014deb5cf504c2c10ee424bd33590f0a4f22e01d8f",
      warning_type: "Cross-Site Request Forgery",
      line: 1,
      message: /^`protect_from_forgery`\ should\ be\ called\ /,
      confidence: 0,
      relative_path: "app/controllers/application_controller.rb",
      code: nil,
      user_input: nil
  end
end
