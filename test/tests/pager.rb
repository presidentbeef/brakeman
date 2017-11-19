require_relative '../test'
require "brakeman/report/pager"

class ReportPagerTests < Minitest::Test
  def setup
    @@text ||= "Here is some text for your tests\n" * 100
  end

  def test_no_pager
    out = StringIO.new
    pager = Brakeman::Pager.new(nil, :none, out)

    pager.page_output(@@text)

    assert_equal @@text, out.string
  end

  def test_highline
    out = StringIO.new
    $stdin = StringIO.new("\r\r\r\r\r\r\r")
    pager = Brakeman::Pager.new(nil, :highline, out)

    pager.page_output(@@text)

    assert out.string.include? "Here is some text"
    assert out.string.include? "press enter/return to continue or q to stop"
  ensure
    $stdin = STDIN
  end

  def test_in_ci_test
    pager = Brakeman::Pager.new(Brakeman::Tracker.new(nil))

    if ENV["CI"]
      assert pager.in_ci?
    else
      refute pager.in_ci?
    end
  end

  def test_set_color
    pager = Brakeman::Pager.new(Brakeman::Tracker.new(nil))
    pager.set_color
  end
end
