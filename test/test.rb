#Set paths
TEST_PATH = File.expand_path(File.dirname(__FILE__))
$LOAD_PATH.unshift "#{TEST_PATH}/../lib"

begin
  require 'simplecov'
  SimpleCov.start do
    add_filter 'lib/ruby_parser/ruby18_parser.rb'
    add_filter 'lib/ruby_parser/ruby19_parser.rb'
    add_filter 'lib/ruby_parser/ruby_lexer.rb'
    add_filter 'lib/ruby_parser/ruby_parser_extras.rb'
  end
rescue LoadError => e
  $stderr.puts "Install simplecov for test coverage report"
end

require 'brakeman'
require 'brakeman/scanner'
require 'test/unit'

#Helper methods for running scans
module BrakemanTester
  class << self
    #Run scan on app at the given path
    def run_scan path, name = nil, opts = {}
      opts.merge! :app_path => "#{TEST_PATH}/apps/#{path}",
        :quiet => false,
        :url_safe_methods => [:ensure_valid_proto!]

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
        opts.all? do |k,v|
          v === w.send(k)
        end
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

  def test_zero_errors
    assert_equal 0, report[:errors].length
  end
end

module BrakemanTester::RescanTestHelper
  attr_reader :original, :rescan, :rescanner

  #Takes care of copying files to a temporary directory, scanning the files,
  #performing operations in the block (if provided), then rescanning the files
  #given in `changed`.
  #
  #Provide an array of changed files for rescanning.
  def before_rescan_of changed, app = "rails3.2", options = {}
    changed = [changed] unless changed.is_a? Array

    Dir.mktmpdir do |dir|
      @dir = dir
      options = {:app_path => dir, :debug => false}.merge(options)

      FileUtils.cp_r "#{TEST_PATH}/apps/#{app}/.", dir
      @original = Brakeman.run options

      yield dir if block_given?

      @rescanner = Brakeman::Rescanner.new(@original.options, @original.processor, changed)
      @rescan = @rescanner.recheck

      assert_existing
    end
  end

  def fixed
    rescan.fixed_warnings
  end

  def new
    rescan.new_warnings
  end

  def existing
    rescan.existing_warnings
  end

  #Check how many fixed warnings were reported
  def assert_fixed expected
    assert_equal expected, fixed.length, "Expected #{expected} fixed warnings, but found #{fixed.length}"
  end

  #Check how many new warnings were reported
  def assert_new expected
    assert_equal expected, new.length, "Expected #{expected} new warnings, but found #{new.length}"
  end

  #Check how many existing warnings were reported
  def assert_existing
    expected = (@rescan.old_results.all_warnings.length - fixed.length)

    assert_equal expected, existing.length, "Expected #{expected} existing warnings, but found #{existing.length}"
  end

  def assert_changes expected = true
    assert_equal expected, rescanner.changes
  end

  def assert_reindex *types
    if types == [:none]
      assert rescanner.reindex.empty?, "Expected no reindexing, got #{rescanner.reindex.inspect}"
    else
      assert_equal Set.new(types), rescanner.reindex
    end
  end

  def full_path file
    File.expand_path file, @dir
  end

  def remove file
    path = full_path file

    assert File.exist?(path), "Could not find #{path} to delete"
    File.delete path
    assert_equal false, File.exist?(path)
  end

  def append file, code
    File.open full_path(file), "a" do |f|
      f.puts code
    end
  end

  def replace_with_sexp file
    path = full_path file
    parsed = parse File.read path

    output = yield parsed

    File.open path, "w" do |f|
      f.puts Brakeman::OutputProcessor.new.process output
    end
  end

  def replace file, pattern, replacement
    path = full_path file
    input = File.read path
    input.sub! pattern, replacement

    File.open path, "w" do |f|
      f.puts input
    end
  end

  def write_file file, content
    File.open full_path(file), "w+" do |f|
      f.puts content
    end
  end

  def remove_method file, method_name
    replace_with_sexp file do |parsed|
      class_body = parsed.body

      class_body.reject! do |node|
        node.is_a? Sexp and
        node.node_type == :defn and
        node.method_name == method_name
      end

      parsed.body = class_body

      parsed
    end
  end

  def add_method file, code
    parsed_method = parse code

    replace_with_sexp file do |parsed|
      parsed.body = parsed.body << parsed_method

      parsed
    end
  end

  def parse code
    RubyParser.new.parse code
  end
end

module BrakemanTester::DiffHelper
  def assert_fixed expected, diff = @diff
    assert_equal expected, diff[:fixed].length, "Expected #{expected} fixed warnings, but found #{diff[:fixed].length}"
  end

  def assert_new expected, diff = @diff
    assert_equal expected, diff[:new].length, "Expected #{expected} new warnings, but found #{diff[:new].length}"
  end
end

Dir.glob "#{TEST_PATH}/tests/*.rb" do |file|
  require file
end
