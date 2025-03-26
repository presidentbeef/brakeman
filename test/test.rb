#Set paths
unless defined? TEST_PATH
  TEST_PATH = File.expand_path(File.dirname(__FILE__))
  $LOAD_PATH.unshift "#{TEST_PATH}/../lib"
end

begin
  require 'simplecov'

  SimpleCov.start
rescue LoadError
  $stderr.puts "Install simplecov for test coverage report"
end

require 'brakeman'
require 'brakeman/scanner'
require 'minitest/autorun'
require 'minitest/pride'

if ENV["CIRCLECI"]
  require 'minitest/ci'
  Minitest::Ci.report_dir = File.join("test-results", "minitest")
end

if ENV['TEST_PRISM']
  gem 'prism'
  require 'prism'
end

class Minitest::Test
  def assert_nothing_raised *args
    yield
  end
end

#Helper methods for running scans
module BrakemanTester
  class << self
    #Run scan on app at the given path
    def run_scan path, name = nil, opts = {}
      opts.merge! :app_path => "#{TEST_PATH}/apps/#{path}",
        :url_safe_methods => [:ensure_valid_proto!],
        :parallel_checks => false # Something broken with tests+parallel

      if ENV['TEST_PRISM']
        opts[:use_prism] = true
      end

      Brakeman.run(opts).report.to_hash
    end

    def new_tracker options = {}
      Brakeman::Tracker.new(Brakeman::AppTree.new("/tmp/FAKE_BRAKEMAN_PATH#{rand(10000)}"), nil, options)
    end
  end
end

#Helpers for finding warnings in the report
module BrakemanTester::FindWarning
  def assert_warning opts
    warnings = find opts
    refute_equal 0, warnings.length, "No warning found"
    assert_equal 1, warnings.length, "Matched more than one warning"
  end

  def assert_no_warning opts
    warnings = find opts
    assert_equal 0, warnings.length, "Found warning when no warning was expected"
  end

  def warning_table type
    case type
    when :warning, :generic, nil
      :generic_warnings
    when :template
      :template_warnings
    when :controller
      :controller_warnings
    when :model
      :model_warnings
    else
      raise "Unknown warning type: #{type.inspect}"
    end
  end

  def find opts = {}
    warnings = report[warning_table(opts[:type])]

    opts.delete :type

    warnings.select do |w|
      opts.all? do |k,v|
        if k == :relative_path
          v === w.file.relative
        else
          v === w.send(k)
        end
      end
    end
  end
end

#Check that the number of warnings reported are as expected.
#This is mainly to look for new warnings that are not being tested.
module BrakemanTester::CheckExpected
  def test_number_of_warnings
    require 'pp'

    expected.each do |type, number|
      warnings = report[warning_table(type)]

      assert_equal number, warnings.length, lambda { "Expected #{number} #{type} warnings, but found #{warnings.length}:\n#{warnings.map { |w| w.message }.join("\n")}" }
    end
  end

  def test_zero_errors
    assert_equal 0, report[:errors].length, "Unexpected warning found: #{report[:errors].inspect}"
  end

  def test_every_warning_has_file
    [:generic_warnings, :template_warnings, :controller_warnings, :model_warnings].each do |type|
      report[type].each do |w|
        refute_nil w.file, lambda { "Warning did not have a file: #{w.message}" }
      end
    end
  end

  def test_every_warning_has_cwe_id
    [:generic_warnings, :template_warnings, :controller_warnings, :model_warnings].each do |type|
      report[type].each do |w|
        refute_nil w.cwe_id, lambda { "Warning did not have a CWE ID: #{w.message}" }
        assert_kind_of Array, w.cwe_id, lambda { 'Warnings must have a CWE that is an Array'}
        w.cwe_id.each do |cwe|
          assert_kind_of Integer, cwe, lambda { 'Warnings must have a CWE IDs that are Integers'}
        end
      end
    end
  end
end

module BrakemanTester::RescanTestHelper
  attr_reader :original, :rescan, :rescanner

  @@temp_dirs = {}
  @@scans = {}

  Minitest.after_run do
    @@temp_dirs.each do |_, dir|
      FileUtils.remove_dir(dir, true)
    end
  end

  def self.included _
    unless Brakeman::Rescanner.instance_methods.include? :reindex
      Brakeman::Rescanner.class_eval do
        #For access to internals
        attr_reader :changes, :reindex
      end
    end
  end

  #Takes care of copying files to a temporary directory, scanning the files,
  #performing operations in the block (if provided), then rescanning the files
  #given in `changed`.
  #
  #Provide an array of changed files for rescanning.
  def before_rescan_of changed, app = "rails3.2", options = {}
    changed = [changed] unless changed.is_a? Array

    if @@temp_dirs[app]
      dir = @dir = @@temp_dirs[app]
    else
      dir = @dir = @@temp_dirs[app] = Dir.mktmpdir('brakeman-test')
      FileUtils.cp_r(File.join(TEST_PATH, 'apps', app, '.'), dir)
    end

    options = {app_path: dir, debug: false, support_rescanning: true}.merge(options)

    if @@scans[[app, options]]
      @original = @@scans[[app, options]]
    else
      @@scans[[app, options]] = @original = Brakeman.run(options)
    end

    begin
      yield dir if block_given?

      # Not really sure why we do this..?
      t = Marshal.load(Marshal.dump(@original.marshallable))

      @rescanner = Brakeman::Rescanner.new(t.options, t.processor, changed)
      @rescan = @rescanner.recheck
    ensure
      changed.each do |file|
        original = File.join(TEST_PATH, 'apps', app, file)
        if File.exist? original
          FileUtils.cp original, full_path(file) 
        else
          FileUtils.rm full_path(file)
        end
      end
    end

    assert_existing
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
    assert_equal expected, fixed.length, lambda { "Expected #{expected} fixed warnings, but found #{fixed.length}:\n#{fixed.map {|w| "\t#{w.message}" }.join("\n")}" }
  end

  #Check how many new warnings were reported
  def assert_new expected
    assert_equal expected, new.length, lambda {
      "Expected #{expected} new warnings, but found #{new.length}:\n#{new.map {|w| w.to_json}.join("\n")}\n" \
      "Also these are the old ones:\n#{existing.map {|w| w.to_json }.join("\n")}"
    }
  end

  #Check how many existing warnings were reported
  def assert_existing
    expected = (@rescan.old_results.length - fixed.length)

    assert_equal expected, existing.length, "Expected #{expected} existing warnings, but found #{existing.length}"
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

  def rename from_file, to_file
    require 'fileutils'
    old_path = full_path from_file
    new_path = full_path to_file

    assert File.exist?(old_path), "Could not find #{old_path} to delete"

    FileUtils.mv old_path, new_path
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
    require 'fileutils'
    path = full_path(file)
    FileUtils.mkdir_p(File.dirname(path))
    File.open path, "w" do |f|
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

if __FILE__ == $0
  Dir.glob "#{TEST_PATH}/tests/*.rb" do |file|
    require file
  end
end
