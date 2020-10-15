require_relative '../test'
require 'json'

class SonarOutputTests < Minitest::Test
  def setup
    @@sonar ||= JSON.parse(Brakeman.run("#{TEST_PATH}/apps/rails3.2").report.to_sonar)
  end

  def test_for_expected_keys
    assert (@@sonar.keys - ["issues"]).empty?
  end

  def test_for_issues_keys
    issues_keys = ["engineId", "ruleId", "severity", "type", "primaryLocation", "effortMinutes"]
    @@sonar["issues"].each do |warning|
      assert (warning.keys - issues_keys).empty?
    end
    
  end

end
