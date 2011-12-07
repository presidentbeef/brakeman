class UtilTests < Test::Unit::TestCase
  def util
    Class.new.extend Brakeman::Util
  end

  def test_cookies?
    assert util.cookies?(Ruby18Parser.new.parse 'cookies[:x][:y][:z]')
  end

  def test_params?
    assert util.params?(Ruby18Parser.new.parse 'params[:x][:y][:z]')
  end
end
