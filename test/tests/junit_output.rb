require_relative '../test'
require 'rexml/document'

class JUnitOutputTests < Minitest::Test
  def setup
    @@document ||= REXML::Document.new(Brakeman.run("#{TEST_PATH}/apps/rails3.2").report.to_junit)
  end

  def test_for_ignored_warnings
    assert @@document.get_elements('/testsuites/brakeman:ignored/brakeman:warning').length == 0

    document = REXML::Document.new(Brakeman.run("#{TEST_PATH}/apps/rails4").report.to_junit)
    ignored_warnings = document.get_elements('/testsuites/brakeman:ignored/brakeman:warning')
    assert_equal 1, ignored_warnings.length
  end

  def test_for_errors
    assert @@document.get_elements('/testsuites/brakeman:errors/brakeman:error').length == 0

    tracker = Brakeman.run("#{TEST_PATH}/apps/rails3.2")
    tracker.error Exception.new "some message"
    document = REXML::Document.new(tracker.report.to_junit)
    elements = document.get_elements('/testsuites/brakeman:errors/brakeman:error')
    assert_equal elements.map { |e| e.attribute('brakeman:message').to_s }, ["some message"]
  end

  def test_for_obsolete
    document = REXML::Document.new(Brakeman.run("#{TEST_PATH}/apps/rails4").report.to_junit)
    obsolete = document.get_elements('/testsuites/brakeman:obsolete/brakeman:warning')
      .map { |e| e.attribute('brakeman:fingerprint').to_s }
    assert_equal ["abcdef01234567890ba28050e7faf1d54f218dfa9435c3f65f47cb378c18cf98"], obsolete
  end

  def test_paths
    elements = @@document.get_elements('/testsuites/testsuite/testcase/failure')
    assert elements.all? { |e| not e.attribute('brakeman:file').to_s.start_with? "/" }
  end
end
