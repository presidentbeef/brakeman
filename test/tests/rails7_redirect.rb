require_relative '../test'
require 'brakeman/rescanner'

class RailsConfiguration < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::RescanTestHelper

  def report
    @rescanner.tracker.report.to_hash
  end

  def test_rails7_default_no_open_redirects
    before_rescan_of ['config/application.rb'], 'rails7' do
      replace 'config/application.rb', 'config.action_controller.raise_on_open_redirects = false', 'config.action_controller.raise_on_open_redirects = true'
    end

    assert_fixed 3

    assert_no_warning check_name: "Redirect",
      type: :warning,
      warning_code: 18,
      fingerprint: "0e6b36e8598a024ef8832d7af1a5b0089f6b00f96c17e2ccdb87aca012e6f76f",
      warning_type: "Redirect",
      line: 13,
      message: /^Possible\ unprotected\ redirect/,
      confidence: 0,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, nil, :redirect_to, s(:or, s(:call, s(:params), :[], s(:lit, :redirect_url)), s(:str, "/"))),
      user_input: s(:call, s(:params), :[], s(:lit, :redirect_url))

    assert_no_warning check_name: "Redirect",
      type: :warning,
      warning_code: 18,
      fingerprint: "81ee1b43b1a16a2e143669adb3259407bb462f1963d339717662d9271a154909",
      warning_type: "Redirect",
      line: 29,
      message: /^Possible\ unprotected\ redirect/,
      confidence: 0,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, nil, :redirect_back, s(:hash, s(:lit, :fallback_location), s(:call, s(:params), :[], s(:lit, :x)))),
      user_input: s(:call, s(:params), :[], s(:lit, :x))

    assert_no_warning check_name: "Redirect",
      type: :warning,
      warning_code: 18,
      fingerprint: "e5aed5eb26b588f3cb6f9f7d34c63ceffcb574348c4fd3c8464e11cab16ed3e3",
      warning_type: "Redirect",
      line: 33,
      message: /^Possible\ unprotected\ redirect/,
      confidence: 0,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, nil, :redirect_back_or_to, s(:call, s(:params), :[], s(:lit, :x))),
      user_input: s(:call, s(:params), :[], s(:lit, :x))
  end
end
