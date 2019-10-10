require_relative '../test'

class FileParserTests < Minitest::Test
  def setup
    @tracker = BrakemanTester.new_tracker
    @file_parser = Brakeman::FileParser.new(@tracker)
  end

  def test_parse_error
    @file_parser.parse_ruby <<-RUBY, "/tmp/BRAKEMAN_FAKE_PATH/test.rb"
        x =
    RUBY

    assert_equal 1, @tracker.errors.length
  end

  def test_parse_error_shows_newer_failure
    @file_parser.parse_ruby <<-RUBY, "/tmp/BRAKEMAN_FAKE_PATH/test.rb"
    blah(x: 1)
    thing do
    RUBY

    assert_equal 1, @tracker.errors.length

    if RubyParser::Parser::VERSION.split(".").map(&:to_i).zip([3,14,0]).all? { |a, b| a >= b }
      assert_match(/parse error on value false \(\$end\)/, @tracker.errors.first[:error])
    else
      assert_match(/parse error on value \"\$end\" \(\$end\)/, @tracker.errors.first[:error])
    end
  end
end
