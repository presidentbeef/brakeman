abort "Please run using test/test.rb" unless defined? BrakemanTester

Rails4 = BrakemanTester.run_scan "rails4", "Rails 4"

class Rails4Tests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected
  
  def report
    Rails4
  end

  def expected
    @expected ||= {
      :controller => 0,
      :model => 0,
      :template => 0,
      :warning => 1
    }
  end

  def test_session_secret_token
    assert_warning :type => :warning,
      :warning_type => "Session Setting",
      :line => 12,
      :message => /^Session\ secret\ should\ not\ be\ included\ in/,
      :confidence => 0,
      :file => /secret_token\.rb/
  end
end
