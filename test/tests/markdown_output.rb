class TestMarkdownOutput < Test::Unit::TestCase
  def setup
    @@report ||= Brakeman.run(
      :app_path       => "#{TEST_PATH}/apps/rails2",
      :quiet          => true,
      :run_all_checks => true
    ).report.to_markdown
  end

  def test_reported_warnings
    if Brakeman::Scanner::RUBY_1_9
      assert_equal 172, @@report.lines.to_a.size
    else
      assert_equal 173, @@report.lines.to_a.size
    end
  end
end
