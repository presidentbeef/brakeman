#Set paths
TEST_PATH = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift "#{TEST_PATH}/../lib"

OPTIONS = {}

require 'set'
require 'test/unit'
require 'scanner'

#Helper methods for running scans
module BrakemanTester
  class << self
    #Set environment for scan
    def setup_scan opts = {}
      ::OPTIONS.clear
      
      #Set defaults
      ::OPTIONS.merge! :skip_checks => Set.new,
        :check_arguments => true, 
        :safe_methods => Set.new,
        :min_confidence => 2,
        :combine_locations => true,
        :collapse_mass_assignment => true,
        :ignore_redirect_to_model => true,
        :ignore_model_output => false,
        :parallel_checks => true

      #Set options for this scan
      ::OPTIONS.merge! opts

      #Force correct parser
      Object.instance_eval { remove_const :RoutesProcessor }
      load 'processors/route_processor.rb'
    end

    #Run scan on app at the given path
    def run_scan path, name = nil, opts = {}
      name ||= path
      path = File.expand_path "#{TEST_PATH}/apps/#{path}"

      setup_scan opts.merge(:app_path => path)

      announce "Processing #{name} application..."

      tracker = Scanner.new(path).process
      tracker.run_checks

      Report.new(tracker).to_test
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
