class TestTabsOutput < Test::Unit::TestCase
  Report = Brakeman.run(:app_path => "#{TEST_PATH}/apps/rails2", :quiet => true).report.to_tabs

  def test_reported_warnings
    if Brakeman::Scanner::RUBY_1_9
      assert_equal 101, Report.lines.to_a.count
    else
      assert_equal 102, Report.lines.to_a.count
    end
  end
end
