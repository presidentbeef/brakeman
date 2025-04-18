require_relative '../test'
require 'rexml/document'

class JUnitOutputTests < Minitest::Test
  NO_LINE_REPORT_CHECKS = %w[
    CheckDefaultRoutes
    CheckModelAttrAccessible
  ]

  def setup
    @@document ||= REXML::Document.new(Brakeman.run("#{TEST_PATH}/apps/rails3.2").report.to_junit)
  end

  def test_document_structure
    assert_equal "testsuites", @@document.root.name
    assert @@document.root.elements.count > 0, "No test suites found"

    @@document.root.elements.each do |testsuite|
      assert_equal "testsuite", testsuite.name
      assert testsuite.elements.count > 0, "No elements in test suite"

      # Check testcase elements
      testsuite.elements.each("testcase") do |testcase|
        assert_equal "testcase", testcase.name
        assert testcase.elements["failure"], "Missing failure element in testcase"
      end
    end
  end

  def test_testsuite_attributes
    @@document.root.elements.each do |testsuite|
      # Required attributes for testsuite
      assert testsuite.attributes["id"], "Missing id attribute"
      assert_equal "brakeman", testsuite.attributes["package"]
      assert testsuite.attributes["file"], "Missing file attribute"
      assert testsuite.attributes["timestamp"], "Missing timestamp attribute"
      assert testsuite.attributes["tests"], "Missing tests attribute"
      assert testsuite.attributes["failures"], "Missing failures attribute"
      assert testsuite.attributes["errors"], "Missing errors attribute"
      assert testsuite.attributes["time"], "Missing time attribute"
    end
  end

  def test_testcase_attributes
    @@document.root.elements.each do |testsuite|
      testsuite.elements.each("testcase") do |testcase|
        # Required attributes for testcase
        assert testcase.attributes["name"], "Missing name attribute"
        assert testcase.attributes["file"], "Missing file attribute"
        unless NO_LINE_REPORT_CHECKS.any? { |check| testcase.attributes["name"].include?(check) }
          assert testcase.attributes["line"], "Missing line attribute: #{testcase.attributes}"
        end
        assert testcase.attributes["time"], "Missing time attribute"
      end
    end
  end

  def test_failure_attributes
    @@document.root.elements.each do |testsuite|
      testsuite.elements.each("testcase") do |testcase|
        failure = testcase.elements["failure"]
        assert failure, "Missing failure element"

        # Required attributes for failure
        assert failure.attributes["message"], "Missing message attribute"
        assert failure.attributes["type"], "Missing type attribute"
        assert failure.text.strip.length > 0, "Failure text is empty"
      end
    end
  end
end
