class UtilTests < Test::Unit::TestCase
  def setup
    if RUBY_VERSION =~ /^1\.9/
      @ruby_parser = Ruby19Parser
    else
      @ruby_parser = RubyParser
    end
  end

  def util
    Class.new.extend Brakeman::Util
  end

  def test_cookies?
    assert util.cookies?(@ruby_parser.new.parse 'cookies[:x][:y][:z]')
  end

  def test_params?
    assert util.params?(@ruby_parser.new.parse 'params[:x][:y][:z]')
  end
end
