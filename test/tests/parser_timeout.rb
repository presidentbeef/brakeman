require_relative '../test'
require 'brakeman/rescanner'

class ParserTimeoutTests < Minitest::Test
  include BrakemanTester::RescanTestHelper

  def test_timeout
    before_rescan_of "lib/large_file.rb", "rails5.2", { parser_timeout: 1 } do
      random_ruby = Array.new(10000) { "def x_#{rand(1000)}\nputs '#{"**" * 1000}'\nend" }.join("\n")
      write_file "lib/large_file.rb", random_ruby
    end

    assert_equal 1, @rescanner.tracker.errors.length

    timeout_error = @rescanner.tracker.errors.first
    assert_match(/Parsing .* took too long \(> 1 seconds\)/, timeout_error[:error])
  end
end
