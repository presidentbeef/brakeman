require_relative '../test'

class Rails7Tests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    @@report ||= BrakemanTester.run_scan "rails7", "Rails 7", :run_all_checks => true
  end

  def expected
    @@expected ||= {
      :controller => 0,
      :model => 0,
      :template => 0,
      :warning => 2
    }
  end

  def test_missing_encryption_1
    assert_warning :type => :warning,
      :warning_code => 109,
      :fingerprint => "6a26086cd2400fbbfb831b2f8d7291e320bcc2b36984d2abc359e41b3b63212b",
      :warning_type => "Missing Encryption",
      :line => 1,
      :message => /^The\ application\ does\ not\ force\ use\ of\ HT/,
      :confidence => 0,
      :relative_path => "config/environments/production.rb",
      :code => nil,
      :user_input => nil
  end

  def test_cross_site_scripting_CVE_2022_32209_allowed_tags_initializer
    assert_warning check_name: "SanitizeConfigCve",
      type: :warning,
      warning_code: 124,
      fingerprint: "c2cc471a99036432e03d83e893fe748c2b1d5c40a39e776475faf088717af97d",
      warning_type: "Cross-Site Scripting",
      line: 1,
      message: /^rails\-html\-sanitizer\ 1\.4\.2\ has\ an\ XSS\ vu/,
      confidence: 0,
      relative_path: "config/initializers/sanitizers.rb",
      code: s(:attrasgn, s(:colon2, s(:colon2, s(:const, :Rails), :Html), :SafeListSanitizer), :allowed_tags=, s(:array, s(:str, "select"), s(:str, "a"), s(:str, "style"))),
      user_input: nil
  end
end
