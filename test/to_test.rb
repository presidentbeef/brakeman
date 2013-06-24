#This is a utility script for generating tests from reported warnings.
#
#It is not heavily tested. It is mostly for the convenience of coders. Sometimes
#it generates broken code which will need to be fixed manually.
#
#Usage:
#
#  ruby to_test.rb apps/some_app > tests/test_some_app.rb`

# Set paths
$LOAD_PATH.unshift "#{File.expand_path(File.dirname(__FILE__))}/../lib"

require 'brakeman'
require 'ruby_parser'
require 'ruby_parser/bm_sexp'
require 'brakeman/options'
require 'brakeman/report/report_base'

class Brakeman::Report::Tests < Brakeman::Report::Base
  def generate_report
    counter = 0

    name = camelize File.basename(tracker.options[:app_path])

    output = <<-RUBY
abort "Please run using test/test.rb" unless defined? BrakemanTester

#{name} = BrakemanTester.run_scan "#{File.basename tracker.options[:app_path]}", "#{name}"

class #{name}Tests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def expected
    @expected ||= {
      :controller => #{@checks.controller_warnings.length},
      :model => #{@checks.model_warnings.length},
      :template => #{@checks.template_warnings.length},
      :warning => #{@checks.warnings.length} }
  end

  def report
    #{name}
  end

    RUBY

    output << @checks.all_warnings.map do |w|
      counter += 1

      <<-RUBY
  def test_#{w.warning_type.to_s.downcase.tr(" -", "__")}_#{counter}
    assert_warning :type => #{w.warning_set.inspect},
      :warning_code => #{w.warning_code},
      :fingerprint => #{w.fingerprint.inspect},
      :warning_type => #{w.warning_type.inspect},
      #{w.line ? ":line => " : "#noline"}#{w.line},
      :message => /^#{Regexp.escape w.message[0,40]}/,
      :confidence => #{w.confidence},
      :relative_path => #{w.relative_path.inspect}
  end
      RUBY
    end.join("\n")

    output << "\nend"
  end
end

options, _ = Brakeman::Options.parse!(ARGV)

unless options[:app_path]
  if ARGV[-1].nil?
    options[:app_path] = File.expand_path "."
  else
    options[:app_path] = File.expand_path ARGV[-1]
  end
end

tracker = Brakeman.run options

puts Brakeman::Report::Tests.new(nil, tracker).generate_report
