require_relative '../test'
require 'rexml/document'

class JUnitOutputTests < Minitest::Test
  def setup
    @@document ||= REXML::Document.new(Brakeman.run("#{TEST_PATH}/apps/rails3.2").report.to_junit)
  end

  def test_paths
    elements = @@document.get_elements('/testsuites/testsuite/testcase/failure')
    assert elements.all? { |e| not e.attribute('brakeman:file').to_s.start_with? "/" }
  end
end
