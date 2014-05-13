class TestMarkdownOutput < Test::Unit::TestCase
  Report = Brakeman.run(:app_path => "#{TEST_PATH}/apps/rails2", :quiet => true).report.to_markdown

  def test_reported_warnings
    if Brakeman::Scanner::RUBY_1_9
      assert_equal 167, Report.lines.to_a.count
    else
      assert_equal 168, Report.lines.to_a.count
    end
  end
end
