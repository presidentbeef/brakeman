require_relative '../test'

class LoggerTests < Minitest::Test
  def test_logger_type
    assert_kind_of Brakeman::Logger::Debug, Brakeman::Logger.get_logger(debug: true)
    assert_kind_of Brakeman::Logger::Quiet, Brakeman::Logger.get_logger(quiet: true)
    assert_kind_of Brakeman::Logger::Plain, Brakeman::Logger.get_logger(report_progress: false)
    assert_kind_of Brakeman::Logger::Plain, Brakeman::Logger.get_logger({}, StringIO.new)
    assert_kind_of Brakeman::Logger::Console, Brakeman::Logger.get_logger({}, $stdout)
  end

  def test_color_options
    refute Brakeman::Logger.get_logger({}).color?

    refute Brakeman::Logger.get_logger(output_color: false).color?

    # No color unless TTY
    refute Brakeman::Logger.get_logger({output_color: true}, StringIO.new).color?
    refute Brakeman::Logger.get_logger({}, StringIO.new).color?

    assert Brakeman::Logger.get_logger({output_color: true}, $stderr).color?

    # :force forces color
    assert Brakeman::Logger.get_logger({output_color: :force}, StringIO.new).color?
  end
end
