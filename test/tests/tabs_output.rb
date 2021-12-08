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
    assert_equal 112, @@report.lines.to_a.count, 'Did you add new vulnerabilities to the Rails 2 app?'
  end
end
