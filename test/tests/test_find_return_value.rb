require 'brakeman/processors/lib/find_return_value'

class FindReturnValueTests < Test::Unit::TestCase
  def assert_returns expected, original, env = nil
    expected = RubyParser.new.parse(expected) if expected.is_a? String
    original = RubyParser.new.parse(original) if original.is_a? String
    return_value = Brakeman::FindReturnValue.return_value original, env

    assert_equal expected, return_value
  end

  def test_sanity
    assert_returns "1", "1"
  end

  def test_implicit_return
    assert_returns "1", <<-RUBY
      def x
        1
      end
    RUBY
  end

  def test_explicit_return
    #This is kind of wrong
    assert_returns "'hi' or 1", <<-RUBY
      def x
        return 'hi'
        1
      end
    RUBY
  end

  def test_multiple_explicit_returns
    assert_returns '1 or 2', <<-RUBY
      def x
        if something
          return 1
        else
          return 2
        end
      end
    RUBY
  end

  def test_multiple_implicit_returns
    assert_returns '1 or 2', <<-RUBY
      def x
        if something
          1
        else
          2
        end
      end
    RUBY
  end

  def test_block_of_code
    assert_returns '@b', <<-RUBY
      def x
        something
        something
        something_else
        @b
      end
    RUBY
  end

  def test_parameters
    env = SexpProcessor::Environment.new
    env[s(:lvar, :y)] = s(:lit, 1)

    assert_returns '2', <<-RUBY, env
      def x y
        y = y + 1
        y
      end
    RUBY
  end

  def test_assign_as_implicit_return
    env = SexpProcessor::Environment.new
    env[s(:lvar, :y)] = s(:lit, 1)

    assert_returns '2', <<-RUBY, env
      def x y
        y = y + 1
      end
    RUBY
  end

  def test_iassgn_as_implicit_return
    env = SexpProcessor::Environment.new
    env[Sexp.new(:ivar, :@y)] = Sexp.new(:lit, 2)

    assert_returns '1', <<-RUBY, env
      def x
        @y = 1
      end
    RUBY

    assert_equal env[Sexp.new(:ivar, :@y)], Sexp.new(:lit, 1)
  end

  def test_local_aliasing
    assert_returns "'a'", <<-RUBY
      def x
        y = 1
        blah_blah
        y = 2
        blah_blah
        y = 'a'
        blah_blah
        y
      end
    RUBY
  end

  def test_ivar_aliasing
    env = SexpProcessor::Environment.new
    env[s(:ivar, :@y)] = s(:lit, 1)

    assert_returns "'a'", <<-RUBY, env
      def x
        @y = 1
        blah_blah
        @y = 'a'
        blah_blah
        z = @y
        blah_blah
        z
      end
    RUBY
  end
end
