#Set paths
TEST_PATH = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift "#{TEST_PATH}/../lib"

require 'brakeman'
require 'brakeman/scanner'
require 'test/unit'

#Helper methods for running scans
module BrakemanTester
  class << self
    #Run scan on app at the given path
    def run_scan path, name = nil, opts = {}
      opts.merge! :app_path => "#{TEST_PATH}/apps/#{path}",
        :quiet => false

      announce "Processing #{name} application..."

      Brakeman.run(opts).report.to_test
    end

    #Make an announcement
    def announce msg
      $stderr.puts "-" * 40
      $stderr.puts msg
      $stderr.puts "-" * 40
    end
  end
end

#Helpers for finding warnings in the report
module BrakemanTester::FindWarning
  def assert_warning opts
    warnings = find opts
    assert_not_equal 0, warnings.length, "No warning found"
    assert_equal 1, warnings.length, "Matched more than one warning"
  end 

  def assert_no_warning opts
    warnings = find opts
    assert_equal 0, warnings.length, "Unexpected warning found"
  end

  def find opts = {}, &block
    t = opts[:type]
    if t.nil? or t == :warning
      warnings = report[:warnings]
    else
      warnings = report[(t.to_s << "_warnings").to_sym]
    end

    opts.delete :type

    result = if block
      warnings.select block
    else
      warnings.select do |w|
        flag = true
        opts.each do |k,v|
          unless v === w.send(k)
            flag = false
            break
          end
        end
        flag
      end
    end

    result
  end
end

#Check that the number of warnings reported are as expected.
#This is mainly to look for new warnings that are not being tested.
module BrakemanTester::CheckExpected
  def test_number_of_warnings
    expected.each do |type, number|
      if type == :warning
        warnings = report[:warnings]
      else
        warnings = report[(type.to_s << "_warnings").to_sym]
      end

      assert_equal number, warnings.length, "Expected #{number} #{type} warnings, but found #{warnings.length}"
    end
  end
end

Dir.glob "#{TEST_PATH}/tests/*.rb" do |file|
  require file
end
