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

    if RubyParser::Parser::VERSION.split(".").map(&:to_i).zip([3,14,0]).all? { |a, b| a >= b }
      assert_match(/parse error on value false \(\$end\)/, @tracker.errors.first[:error])
    else
      assert_match(/parse error on value \"\$end\" \(\$end\)/, @tracker.errors.first[:error])
    end
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
