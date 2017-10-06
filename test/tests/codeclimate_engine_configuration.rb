require_relative '../test'
require 'brakeman/codeclimate/engine_configuration'

class EngineConfigurationTests < Minitest::Test
  def test_keys_exist
    config = {
      "include_paths" => ["/foo"]
    }
    assert_equal [:app_path, :only_files, :output_files, :output_format, :pager, :quiet],
      Brakeman::Codeclimate::EngineConfiguration.new(config).options.keys.sort
  end

  def test_debug_key
    config = {
      "config" => {
        "debug" => "true"
      }
    }
    assert Brakeman::Codeclimate::EngineConfiguration.new(config).options[:debug]
    assert !Brakeman::Codeclimate::EngineConfiguration.new(config).options[:report_progress]
  end

  def test_include_paths
    config = {
      "include_paths" => ["/foo/bar", nil, "/fizz/buzz"]
    }
    assert_equal ["/foo/bar", "/fizz/buzz"],
      Brakeman::Codeclimate::EngineConfiguration.new(config).options[:only_files]
  end

  def test_output_format
    assert_equal :codeclimate,
      Brakeman::Codeclimate::EngineConfiguration.new.options[:output_format]
  end

  def test_app_path
    assert_equal Dir.pwd,
      Brakeman::Codeclimate::EngineConfiguration.new.options[:app_path]
  end
end
