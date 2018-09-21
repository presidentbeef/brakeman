require_relative '../test'

class RailsWithEmptySecretsYmlTests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def expected
    @expected ||= {
      :controller => 0,
      :model => 0,
      :template => 0,
      :generic => 0 }
  end

  def report
    @RailsWithEmptySecretsYml ||= BrakemanTester.run_scan(
      "rails_with_empty_secrets_yml",
      "RailsWithEmptySecretsYml"
    )
  end
end
