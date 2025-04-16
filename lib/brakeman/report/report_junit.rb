require 'time'
require 'stringio'
Brakeman.load_brakeman_dependency 'rexml/document'

class Brakeman::Report::JUnit < Brakeman::Report::Base
  def generate_report
    io = StringIO.new
    doc = REXML::Document.new
    doc.add REXML::XMLDecl.new '1.0', 'UTF-8'

    test_suites = REXML::Element.new 'testsuites'

    hostname = `hostname`.strip
    i = 0
    all_warnings
      .map { |warning| [warning.file, [warning]] }
      .reduce({}) { |entries, entry|
        key, value = entry
        entries[key] = entries[key] ? entries[key].concat(value) : value
        entries
      }
      .each { |file, warnings|
        i += 1
        test_suite = test_suites.add_element 'testsuite'
        test_suite.add_attribute 'id', i
        test_suite.add_attribute 'package', 'brakeman'
        test_suite.add_attribute 'file', file.relative
        test_suite.add_attribute 'timestamp', tracker.start_time.strftime('%FT%T')
        test_suite.add_attribute 'hostname', hostname == '' ? 'localhost' : hostname
        test_suite.add_attribute 'tests', checks.checks_run.length
        test_suite.add_attribute 'failures', warnings.length
        test_suite.add_attribute 'errors', '0'
        test_suite.add_attribute 'time', '0'

        test_suite.add_element 'properties'

        warnings.each { |warning|
          test_case = test_suite.add_element 'testcase'
          test_case.add_attribute 'name', warning.check
          test_case.add_attribute 'file', file.relative
          test_case.add_attribute 'line', warning.line
          test_case.add_attribute 'time', '0'

          failure = test_case.add_element 'failure'
          failure.add_attribute 'message', warning.message
          failure.add_attribute 'type', warning.warning_type
          failure.add_text warning.to_s
        }

        test_suite.add_element 'system-out'
        test_suite.add_element 'system-err'
      }

    doc.add test_suites
    doc.write io
    io.string
  end
end
