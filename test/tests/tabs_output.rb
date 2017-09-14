require_relative '../test'

class TestTabsOutput < Minitest::Test
  def setup
    @@report ||= Brakeman.run(
      :app_path       => "#{TEST_PATH}/apps/rails2",
      :quiet          => true,
      :run_all_checks => true
    ).report.to_tabs
  end

  def test_reported_warnings
    if Brakeman::Scanner::RUBY_1_9
      assert_equal 108, @@report.lines.to_a.count
    else
      assert_equal 109, @@report.lines.to_a.count
    end
  end
end
