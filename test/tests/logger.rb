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
    Brakeman::Logger.get_logger({})
    refute HighLine.use_color?

    Brakeman::Logger.get_logger(output_color: false)
    refute HighLine.use_color?

    # No color unless TTY
    HighLine.use_color = true
    Brakeman::Logger.get_logger({output_color: true}, StringIO.new)
    refute HighLine.use_color?

    HighLine.use_color = true
    Brakeman::Logger.get_logger({}, StringIO.new)
    refute HighLine.use_color?

    HighLine.use_color = false
    Brakeman::Logger.get_logger({output_color: true}, $stderr)
    assert HighLine.use_color?

    HighLine.use_color = false
    Brakeman::Logger.get_logger({output_color: :force}, StringIO.new)
    assert HighLine.use_color?
  end
end
