require_relative '../test'
require 'json'

class JSONOutputTests < Minitest::Test
  def setup
    @@json ||= JSON.parse(Brakeman.run("#{TEST_PATH}/apps/rails3.2").report.to_json)
  end

  def test_for_render_path
    @@json["warnings"].each do |warning|
      is_right_thing = warning.keys.include?("render_path") && (warning["render_path"].nil? or warning["render_path"].is_a? Array)
      assert is_right_thing, "#{warning["render_path"].class} is not right"
    end
  end

  def test_for_render_path_keys
    controller_keys = %w[type class method line file rendered].sort
    template_keys = %w[type name line file rendered].sort
    rendered_keys = %w[name file].sort

    @@json["warnings"].each do |warning|
      if warning["render_path"]
        warning["render_path"].each do |rp|
          case rp["type"]
          when "controller"
            assert_equal controller_keys, rp.keys.sort
          when "template"
            assert_equal template_keys, rp.keys.sort
          else
            raise "Unknown render path type: #{rp["type"]}"
          end

          if rp["rendered"]
            assert_equal rendered_keys, rp["rendered"].keys.sort
          end
        end
      end
    end
  end

  def test_for_expected_keys
    assert (@@json.keys - ["warnings", "ignored_warnings", "scan_info", "errors", "obsolete"]).empty?
  end

  def test_for_scan_info_keys
    info_keys = ["app_path", "rails_version", "security_warnings", "start_time", "end_time", "duration",
                 "checks_performed", "number_of_controllers", "number_of_models", "number_of_templates",
                 "ruby_version", "brakeman_version"]

    assert (@@json["scan_info"].keys - info_keys).empty?
  end

  def test_for_expected_warning_keys
    expected = ["warning_type", "check_name", "message", "file", "link", "code", "location",
      "render_path", "user_input", "confidence", "line", "warning_code", "fingerprint", "cwe_id"]

    @@json["warnings"].each do |warning|
      assert (warning.keys - expected).empty?, "#{(warning.keys - expected).inspect} did not match expected keys"
    end
  end

  def test_for_errors
    assert @@json["errors"].is_a? Array
  end

  def test_for_obsolete
    json = JSON.parse(Brakeman.run("#{TEST_PATH}/apps/rails4").report.to_json)
    assert_equal ["abcdef01234567890ba28050e7faf1d54f218dfa9435c3f65f47cb378c18cf98"], json["obsolete"]
  end

  def test_paths
    assert @@json["warnings"].all? { |w| not w["file"].start_with? "/" }
  end

  def test_template_names_dont_have_renderer
    assert @@json["warnings"].none? { |warning| warning["render_path"] and warning["location"]["template"].include? "(" }
  end

  def test_json_warnings_have_cwes
    @@json["warnings"].each do |warning|
      assert warning["cwe_id"]
      assert_kind_of Array, warning["cwe_id"]
      refute warning["cwe_id"].empty?
    end
  end
end
