# test/tests/safe_method_handler_test.rb

require 'minitest/autorun'
require_relative '../../lib/brakeman/safe_method_handler'

class TestSafeMethodHandler < Minitest::Test
  def test_normalize_method_with_invalid_type
    assert_raises ArgumentError do
      SafeMethodHandler.normalize_method(123)
    end
  end

  def test_normalize_method_with_string_with_dot
    result = SafeMethodHandler.normalize_method("User.find")
    assert_equal('User.find', result, "Should normalize method correctly")
  end

  def test_normalize_method_with_string_with_pound
    result = SafeMethodHandler.normalize_method("User#find")
    assert_equal('User.find', result, "Should normalize method correctly")
  end

  def test_matches_method_with_string_with_dot
    result = SafeMethodHandler.matches?("User.find", :find)
    assert_equal(true, result, "Should match method correctly")
  end

  def test_include_method_with_a_set_of_safe_methods
    methods = [:find, :fragment]
    result = SafeMethodHandler.include?(:find, methods) && SafeMethodHandler.include?(:fragment, methods)
    assert_equal(true, result, "Should include method in set correctly")
  end

  def test_parse_method_identifier_with_invalid_type
    assert_raises ArgumentError do
      SafeMethodHandler.parse_method_identifier(123)
    end
  end

  def test_parse_method_identifier_with_string
    result = SafeMethodHandler.parse_method_identifier("fragment")
    assert_equal({class_name: nil, method_name: :fragment}, result, "Should parse method identifier correctly")
  end

  def test_parse_method_identifier_with_string_with_dot
    result = SafeMethodHandler.parse_method_identifier("Sanitize.fragment")
    assert_equal({class_name: "Sanitize", method_name: :fragment}, result, "Should parse method identifier correctly")
  end
end
