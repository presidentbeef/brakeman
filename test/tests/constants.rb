require_relative '../test'

class ConstantTests < Minitest::Test
  def setup
    @constants = Brakeman::Constants.new
  end

  def assert_alias expected, original, full = false
    tracker = BrakemanTester.new_tracker
    original_sexp = Brakeman::BaseProcessor.new(tracker).process(RubyParser.new.parse original)
    expected_sexp = Brakeman::BaseProcessor.new(tracker).process(RubyParser.new.parse expected)
    processed_sexp = Brakeman::AliasProcessor.new(tracker).process_safely original_sexp

    if full
      assert_equal expected_sexp, processed_sexp
    else
      assert_equal expected_sexp, processed_sexp.last
    end
  end

  def test_constants_yeah
    assert_alias <<-OUTPUT, <<-INPUT, true
      class A
        def x
          puts 1
        end
      end

      X = 1
    OUTPUT
      class A
        def x
          puts X
        end
      end

      X = 1
    INPUT
  end

  def test_constants_issue_453
    assert_alias <<-OUTPUT, <<-INPUT, true
    class User < ActiveRecord::Base
      FOO = ['Baz']
      BAR = 'Qux'

      def variations
        'Baz'.constantize
        'Baz'.constantize
        'Qux'.constantize
        'Qux'.constantize
      end
    end
    OUTPUT
    class User < ActiveRecord::Base
      FOO = ['Baz']
      BAR = 'Qux'

      def variations
        User::FOO.first.constantize
        FOO.first.constantize
        User::BAR.constantize
        BAR.constantize
      end
    end
    INPUT
  end

  def test_constants_basic_lookup
    @constants.add :A, s(:lit, 1)

    assert_equal s(:lit, 1), @constants.get_simple_value(s(:const, :A))
  end

  def test_constants_get_simple_value
    a_b_c = s(:colon2, s(:colon2, s(:const, :A), :B), :C)
    @constants.add :A, s(:lit, 1) # Simple X = 1 uses just symbol for const
    @constants.add a_b_c, s(:lit, 2)
    @constants.add :D, s(:const, :D)

    assert_equal s(:lit, 1), @constants.get_simple_value(s(:const, :A))
    assert_equal s(:lit, 2), @constants.get_simple_value(a_b_c)
    assert_equal s(:lit, 2), @constants.get_simple_value(s(:colon2, s(:const, :B), :C))
    assert_equal s(:lit, 2), @constants.get_simple_value(s(:colon2, s(:colon2, s(:colon3, :A), :B), :C) )
    assert_nil @constants.get_simple_value(s(:colon2, s(:colon3, :B), :C)) # top-level B
    assert_nil @constants.get_simple_value(s(:colon2, s(:const, :A), :C))
    assert_nil @constants.get_simple_value(s(:colon2, s(:const, :C), :B)) # backwards
    assert_nil @constants.get_simple_value(s(:const, :D)) # not a literal
  end

  def test_constants_lookup
    @constants.add :A, s(:lit, 1)
    @constants.add s(:colon2, s(:const, :A), :B), s(:lit, 2)
    @constants.add :D, s(:const, :D)
    @constants.add :Y, s(:lit, 3)

    assert_equal s(:lit, 1), @constants[s(:const, :A)]
    assert_equal s(:lit, 2), @constants[s(:colon2, s(:const, :A), :B)]
    assert_equal s(:const, :D), @constants[s(:const, :D)]
    assert_nil @constants[s(:colon2, s(:call, s(:call, nil, :x), :constantize), :Y)]
  end

  def test_constants_find_all
    @constants.add :A, s(:lit, 1)
    @constants.add s(:colon2, s(:const, :B), :A), s(:lit, 2)

    consts = @constants.find_all s(:const, :A)

    assert_equal 2, consts.length
  end

  def test_constants_context
    @constants.add :A, s(:lit, 1).line(10), file: "file.rb", class: :CoolClass

    const = @constants.find_all(s(:const, :A)).first

    assert_equal s(:lit, 1), const.value
    assert_equal 10, const.value.line
    assert_equal "file.rb", const.file
    assert_equal "file.rb", const.context[:file]
    assert_equal :CoolClass, const.context[:class]
  end

  def test_constant_in_module_should_not_match_different_qualified_path
    # When MY_CONST is defined in both module A and module B,
    # looking up B::MY_CONST should return B's value, not A's
    assert_alias <<-OUTPUT, <<-INPUT, true
    module A
      MY_CONST = 1
    end

    module B
      MY_CONST = 2
    end

    class Foo
      def bar
        2
      end
    end
    OUTPUT
    module A
      MY_CONST = 1
    end

    module B
      MY_CONST = 2
    end

    class Foo
      def bar
        B::MY_CONST
      end
    end
    INPUT
  end

  def test_constant_in_module_should_not_match_undefined_qualified_path
    # When MY_CONST is defined only in module A,
    # looking up B::MY_CONST should NOT resolve to A's value
    assert_alias <<-OUTPUT, <<-INPUT, true
    module A
      MY_CONST = 1
    end

    class Foo
      def bar
        B::MY_CONST
      end
    end
    OUTPUT
    module A
      MY_CONST = 1
    end

    class Foo
      def bar
        B::MY_CONST
      end
    end
    INPUT
  end

  def test_nested_constant_in_module_should_not_match_different_qualified_path
    # When MY_CONST is defined in both A::Z and B::Z,
    # looking up B::Z::MY_CONST should return B::Z's value, not A::Z's
    assert_alias <<-OUTPUT, <<-INPUT, true
    module A
      module Z
        MY_CONST = 1
      end
    end

    module B
      module Z
        MY_CONST = 2
      end
    end

    class Foo
      def bar
        2
      end
    end
    OUTPUT
    module A
      module Z
        MY_CONST = 1
      end
    end

    module B
      module Z
        MY_CONST = 2
      end
    end

    class Foo
      def bar
        B::Z::MY_CONST
      end
    end
    INPUT
  end

  def test_nested_constant_in_module_should_not_match_undefined_qualified_path
    # When MY_CONST is defined only in A::Z,
    # looking up B::Z::MY_CONST should NOT resolve to A::Z's value
    assert_alias <<-OUTPUT, <<-INPUT, true
    module A
      module Z
        MY_CONST = 1
      end
    end

    class Foo
      def bar
        B::Z::MY_CONST
      end
    end
    OUTPUT
    module A
      module Z
        MY_CONST = 1
      end
    end

    class Foo
      def bar
        B::Z::MY_CONST
      end
    end
    INPUT
  end

  def test_qualified_constant_defined_in_module_should_not_prepend_context
    # When B::MY_CONST is explicitly defined (even from within module A),
    # it should be stored as B::MY_CONST, not A::B::MY_CONST
    assert_alias <<-OUTPUT, <<-INPUT, true
    module A
      B::MY_CONST = 1
    end

    class Foo
      def bar
        1
      end
    end
    OUTPUT
    module A
      B::MY_CONST = 1
    end

    class Foo
      def bar
        B::MY_CONST
      end
    end
    INPUT
  end
end
