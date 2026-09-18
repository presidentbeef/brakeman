require_relative '../test'
require 'json'

class SonarOutputTests < Minitest::Test
  def setup
    @@sonar ||= JSON.parse(Brakeman.run("#{TEST_PATH}/apps/rails8").report.to_sonar)
  end

  def test_for_expected_top_level_keys
    assert_equal ["issues", "rules"].sort, @@sonar.keys.sort
  end

  def test_for_rules_keys
    required = ["id", "name", "description", "engineId", "cleanCodeAttribute", "type", "severity", "impacts"]
    @@sonar["rules"].each do |rule|
      assert_equal [], required - rule.keys, "Rule missing keys: #{rule['id']}"
    end
  end

  def test_rules_engine_id
    @@sonar["rules"].each do |rule|
      assert_equal "Brakeman", rule["engineId"]
    end
  end

  def test_rules_impacts
    @@sonar["rules"].each do |rule|
      assert rule["impacts"].is_a?(Array), "impacts should be an Array"
      rule["impacts"].each do |impact|
        assert impact.key?("softwareQuality")
        assert impact.key?("severity")
      end
    end
  end

  def test_rule_ids_are_unique
    ids = @@sonar["rules"].map { |r| r["id"] }
    assert_equal ids.uniq, ids
  end

  def test_for_issues_keys
    required = ["ruleId", "effortMinutes", "primaryLocation"]
    @@sonar["issues"].each do |issue|
      assert_equal [], required - issue.keys, "Issue missing keys"
    end
  end

  def test_issues_reference_valid_rules
    rule_ids = @@sonar["rules"].map { |r| r["id"] }
    @@sonar["issues"].each do |issue|
      assert_includes rule_ids, issue["ruleId"], "Issue references unknown ruleId: #{issue['ruleId']}"
    end
  end

  def test_issues_have_no_engine_id_or_type_or_severity
    @@sonar["issues"].each do |issue|
      assert !issue.key?("engineId"), "Issues should not have engineId (moved to rules)"
      assert !issue.key?("type"), "Issues should not have type (moved to rules)"
      assert !issue.key?("severity"), "Issues should not have severity (moved to rules)"
    end
  end
end
