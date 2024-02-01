require_relative '../test'
require 'brakeman/rescanner'

class ParserTimeoutTests < Minitest::Test
  include BrakemanTester::RescanTestHelper

  def test_timeout
    skip 'Too hard to get this to consistently pass'

    before_rescan_of "lib/large_file.rb", "rails5.2", { parser_timeout: 0.5 } do
      random_ruby = Array.new(10000) { "def x_#{rand(1000)}\nputs '#{"**" * 1000}'\nend" }.join("\n")
      write_file "lib/large_file.rb", random_ruby
    end

    assert_equal 1, @rescanner.tracker.errors.length

    timeout_error = @rescanner.tracker.errors.first
    assert_match(/Parsing .* took too long \(> 0.5 seconds\)/, timeout_error[:error])
  end
end
