require_relative '../test'
require 'rexml/document'

class JUnitOutputTests < Minitest::Test
  def setup
    @@document ||= REXML::Document.new(Brakeman.run("#{TEST_PATH}/apps/rails3.2").report.to_junit)
  end

  def test_for_errors
    assert @@document.get_elements('/testsuites/brakeman:errors/brakeman:error').length == 0
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
