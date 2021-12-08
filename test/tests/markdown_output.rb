require_relative '../test'

class TestMarkdownOutput < Minitest::Test
  def setup
    @@report ||= Brakeman.run(
      :app_path       => "#{TEST_PATH}/apps/rails2",
      :quiet          => true,
      :run_all_checks => true
    ).report.to_markdown
  end

  def test_reported_warnings
    assert_equal 175, @@report.lines.to_a.count, "Did you add vulnerabilities to the Rails 2 app? Update this test please!"
  end
end
