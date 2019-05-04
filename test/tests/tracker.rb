require_relative '../test'

class TrackerTests < Minitest::Test
  def setup
    @tracker = BrakemanTester.new_tracker
  end

  def test_exception_in_error_list
    @tracker.error Exception.new

    assert_equal 1, @tracker.errors.length

    @tracker.errors.each do |e|
      assert e.has_key? :exception
      assert e.has_key? :error
      assert e.has_key? :backtrace

      assert e[:exception].is_a? Exception
      assert e[:error].is_a? String
      assert e[:backtrace].is_a? Array
    end
  end
end
