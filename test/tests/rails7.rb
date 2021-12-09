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
      :warning => 1
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
end
