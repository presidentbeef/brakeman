require_relative '../test'
require 'tempfile'

class FileParserTests < Minitest::Test
  def setup
    @tracker = BrakemanTester.new_tracker
    timeout = 10
    @file_parser = Brakeman::FileParser.new(@tracker.app_tree, timeout)
  end

  def test_parse_error
    tempfile = Tempfile.new
    tempfile.write("x = ")
    tempfile.close

    @file_parser.parse_files([tempfile.path])
    @tracker.add_errors(@file_parser.errors)

    assert_equal 1, @tracker.errors.length
  ensure
    tempfile.unlink
  end

  def test_parse_error_shows_newer_failure
    tempfile = Tempfile.new
    tempfile.write <<-RUBY
    blah(x: 1)
    thing do
    RUBY
    tempfile.close

    @file_parser.parse_files([tempfile.path])
    @tracker.add_errors(@file_parser.errors)

    assert_equal 1, @tracker.errors.length

    rp_version = Gem::Version.new(RubyParser::Parser::VERSION)
    err_re = case
             when rp_version >= Gem::Version.new("3.17.0")
               /parse error on value "\$" \(\$end\)/
             when rp_version >= Gem::Version.new("3.14.0")
               /parse error on value false \(\$end\)/
             else
               /parse error on value \"\$end\" \(\$end\)/
             end

    assert_match(err_re, @tracker.errors.first[:error])
  end

  def test_read_files_reports_error
    tempfile = Tempfile.new
    tempfile.write("x = ")
    tempfile.close

    @file_parser.read_files([tempfile.path]) do |path, contents|
      @file_parser.parse_ruby contents, path
    end

    @tracker.add_errors(@file_parser.errors)

    assert_equal 1, @tracker.errors.length
  end

  def test_parse_ruby_accepts_file_path
    file_path = Brakeman::FilePath.from_app_tree @tracker.app_tree, "config/test.rb"

    parsed = @file_parser.parse_ruby <<-'RUBY', file_path
      "#{__FILE__}"
    RUBY

    assert_equal s(:str, "config/test.rb"), parsed
  end
end
