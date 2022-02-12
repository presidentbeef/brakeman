require_relative '../test'

class TestGithubOutput < Minitest::Test
  def setup
    @@report ||= github_report
  end

  def test_report_format
    assert_equal 43, @@report.lines.count, "Did you add vulnerabilities to the Rails 6 app? Update this test please!"
    @@report.lines.each do |line|
      assert line.start_with?('::'), 'Every line must start with `::`'
      assert_equal 2, line.scan('::').count, 'Every line must have exactly 2 `::`'
    end
  end

  def test_for_errors
    assert_equal 2, @@report.lines.count {|line| line.start_with?('::error') }
    assert_includes @@report, 'file=app/services/balance.rb,line=4'
  end

  private

  def github_report
    tracker = Brakeman.run("#{TEST_PATH}/apps/rails6")
    tracker.error Racc::ParseError.new('app/services/balance.rb:4 :: parse error on value "..." (tDOT3)')
    tracker.error StandardError.new('Something went wrong')
    tracker.report.to_github
  end
end
