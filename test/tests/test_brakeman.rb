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

class SexpTests < Test::Unit::TestCase
  def setup
    if RUBY_VERSION =~ /^1\.9/
      @ruby_parser = Ruby19Parser
    else
      @ruby_parser = RubyParser
    end
  end

  def parse src
    @ruby_parser.new.parse src
  end

  def test_sexp_call
    call = parse "x()"

    assert_equal call.method, :x
    assert_nil call.target
    assert_equal call.args, Sexp.new()
  end
end

class BaseCheckTests < Test::Unit::TestCase
  FakeTracker = Struct.new(:config)

  def setup
    @tracker = FakeTracker.new
    @check = Brakeman::BaseCheck.new @tracker
  end

  def version_between? version, high, low
    @tracker.config = { :rails_version => version }
    @check.send(:version_between?, high, low)
  end

  def test_version_between
    assert version_between?("2.3.8", "2.3.0", "2.3.8")
    assert version_between?("2.3.8", "2.3.0", "2.3.14")
    assert version_between?("2.3.8", "1.0.0", "5.0.0")
  end

  def test_version_not_between
    assert_equal false, version_between?("3.2.1", "2.0.0", "3.0.0")
    assert_equal false, version_between?("3.2.1", "3.0.0", "3.2.0")
    assert_equal false, version_between?("0.0.0", "3.0.0", "3.2.0")
  end

  def test_version_between_longer
    assert_equal false, version_between?("1.0.1.2", "1.0.0", "1.0.1")
  end
end
