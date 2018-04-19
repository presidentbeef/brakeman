require_relative '../test'
require 'brakeman/codeclimate/engine_configuration'

class EngineConfigurationTests < Minitest::Test
  def test_for_expected_keys
    config = {
      "include_paths" => ["/foo"]
    }

    expected = [:app_path, :only_files, :output_files, :output_format, :pager, :quiet]
    actual = Brakeman::Codeclimate::EngineConfiguration.new(config).options.keys.sort
    assert_equal expected, actual
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

  def test_default_app_path
    assert_equal Dir.pwd,
      Brakeman::Codeclimate::EngineConfiguration.new.options[:app_path]
  end

  def test_custom_app_path
    config = {
      "config" => {
        "app_path" => "foo/bar"
      }
    }
    assert_equal File.join(Dir.pwd, "foo/bar"),
      Brakeman::Codeclimate::EngineConfiguration.new(config).options[:app_path]
  end

  def test_custom_app_path_include_paths
    config = {
      "include_paths" => ["foo/bar", "foo/42.rb", "foo/blub/neat", "README", "baz"],
      "config" => {
        "app_path" => "foo"
      }
    }
    assert_equal ["/bar", "/42.rb", "/blub/neat"],
      Brakeman::Codeclimate::EngineConfiguration.new(config).options[:only_files]
  end

  def test_custom_app_path_include_paths_exact_match
    config = {
      "include_paths" => ["foo/"],
      "config" => {
        "app_path" => "foo/"
      }
    }
    assert_equal ["/"],
      Brakeman::Codeclimate::EngineConfiguration.new(config).options[:only_files]
  end

  def test_custom_nested_app_path_include_paths
    config = {
      "include_paths" => ["foo/"],
      "config" => {
        "app_path" => "foo/bar/baz"
      }
    }
    assert_equal ["/"],
      Brakeman::Codeclimate::EngineConfiguration.new(config).options[:only_files]
  end

  def test_custom_nested_app_path_include_paths_no_trailing_slash
    config = {
      "include_paths" => ["foo"],
      "config" => {
        "app_path" => "foo/bar/baz"
      }
    }
    assert_equal ["/"],
      Brakeman::Codeclimate::EngineConfiguration.new(config).options[:only_files]
  end

  def test_custom_nested_app_path_include_paths_not_a_parent
    config = {
      "include_paths" => ["foo/nope"],
      "config" => {
        "app_path" => "foo/bar/baz"
      }
    }
    assert_equal [],
      Brakeman::Codeclimate::EngineConfiguration.new(config).options[:only_files]
  end
end
