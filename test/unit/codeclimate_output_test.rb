require_relative '../test_helper'

class TestCodeClimateOutput < Minitest::Test
  def setup
    @@report ||= Brakeman.run("#{TEST_PATH}/apps/rails2").report.to_codeclimate
    @@issues ||= @@report.split("\0").map { |json| JSON.parse(json) }
  end

  def test_for_expected_keys
    expected = ["type", "check_name", "description", "fingerprint", "categories",
                "severity", "remediation_points", "location", "content"]

    @@issues.each do |issue|
      assert (issue.keys - expected).empty?
    end
  end

  def test_location_key
    @@issues.each do |issue|
      assert issue["location"]["path"].length > 0
      assert issue["location"]["lines"]["begin"] >= 1
      assert issue["location"]["lines"]["end"] >= 1
    end
  end

  def test_content_key
    @@issues.each do |issue|
      assert issue["content"]["body"].length > 0
    end
  end
end
