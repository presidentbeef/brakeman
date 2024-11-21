require_relative "../test"

class Rails8Tests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    @@report ||=
      Date.stub :today, Date.parse("2024-05-13") do
        BrakemanTester.run_scan "rails8", "Rails 8", run_all_checks: true, use_prism: true
      end
  end

  def expected
    @@expected ||= {
      controller: 0,
      model:      0,
      template:   0,
      warning:    0
    }
  end
end
