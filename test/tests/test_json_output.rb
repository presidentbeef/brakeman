JSON_REPORT = MultiJson.load(Brakeman.run("#{TEST_PATH}/apps/rails3.2").report.to_json)

class JSONOutputTests < Test::Unit::TestCase
  def setup
    @json = JSON_REPORT
  end

  def test_for_render_path
    assert @json["warnings"].all? { |warning|
      warning.keys.include?("render_path") and
      (warning["render_path"].nil? or warning["render_path"].is_a? Array)
    }
  end

  def test_for_expected_keys
    assert (@json.keys - ["warnings", "scan_info", "errors"]).empty?
  end

  def test_for_expected_warning_keys
    expected = ["warning_type", "message", "file", "link", "code", "location",
      "render_path", "user_input", "confidence", "line", "warning_code", "fingerprint"]

    @json["warnings"].each do |warning|
      assert (warning.keys - expected).empty?, "#{(warning.keys - expected).inspect} did not match expected keys"
    end
  end

  def test_for_errors
    assert @json["errors"].is_a? Array
  end
end
