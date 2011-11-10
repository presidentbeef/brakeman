class UtilTests < Test::Unit::TestCase
  def util
    Class.new.extend Util
  end

  def test_cookies?
    assert util.cookies?(RubyParser.new.parse 'cookies[:x][:y][:z]')
  end

  def test_params?
    assert util.params?(RubyParser.new.parse 'params[:x][:y][:z]')
  end
end
