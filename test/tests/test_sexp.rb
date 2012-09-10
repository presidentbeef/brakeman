require 'brakeman/processors/base_processor'

class SexpTests < Test::Unit::TestCase
  def setup
    if RUBY_VERSION[/^1\.9/]
      @ruby_parser = ::Ruby19Parser
    else
      @ruby_parser = ::RubyParser
    end
  end

  def parse string
    Brakeman::BaseProcessor.new(nil).process @ruby_parser.new.parse string
  end

  def test_method_call_with_no_args
    exp = parse "x.y"

    assert_equal s(:call, nil, :x, s(:arglist)), exp.target
    assert_equal :y, exp.method
    assert_equal s(), exp.args
    assert_equal s(:arglist), exp.arglist
    assert_nil exp.first_arg
    assert_nil exp.second_arg
  end

  def test_method_call_with_args
    exp = parse 'x.y(1, 2, 3)'

    assert_equal s(:call, nil, :x, s(:arglist)), exp.target
    assert_equal :y, exp.method
    assert_equal s(s(:lit, 1), s(:lit, 2), s(:lit, 3)), exp.args
    assert_equal s(:arglist, s(:lit, 1), s(:lit, 2), s(:lit, 3)), exp.arglist
    assert_equal s(:lit, 1), exp.first_arg
    assert_equal s(:lit, 2), exp.second_arg
  end

  def test_method_call_no_target
    exp = parse 'x 1, 2, 3'

    assert_nil exp.target
    assert_equal :x, exp.method
    assert_equal s(s(:lit, 1), s(:lit, 2), s(:lit, 3)), exp.args
    assert_equal s(:arglist, s(:lit, 1), s(:lit, 2), s(:lit, 3)), exp.arglist
    assert_equal s(:lit, 1), exp.first_arg
    assert_equal s(:lit, 2), exp.second_arg
  end

  def test_method_call_set_target
    exp = parse 'x.y'
    exp.target = :z

    assert_equal :z, exp.target
  end

  def test_method_call_set_args
    exp = parse 'x.y'
    exp.arglist = s(:arglist, s(:lit, 1), s(:lit, 2))

    assert_equal s(:lit, 1), exp.first_arg
    assert_equal s(:lit, 2), exp.second_arg
    assert_equal s(:arglist, s(:lit, 1), s(:lit, 2)), exp.arglist
    assert_equal s(s(:lit, 1), s(:lit, 2)), exp.args
  end

  def test_method_call_with_block
    exp = parse "x do |z|; blah z; end"
    block = exp.block
    call = exp.block_call
    args = exp.block_args

    assert_equal s(:call, nil, :x, s(:arglist)), call
    assert_equal s(:lasgn, :z), args
    assert_equal s(:call, nil, :blah, s(:arglist, s(:lvar, :z))), block
  end

  def test_or
    exp = parse '1 or 2'

    assert_equal s(:lit, 1), exp.lhs
    assert_equal s(:lit, 2), exp.rhs
  end

  def test_and
    exp = parse '1 and 2'

    assert_equal s(:lit, 1), exp.lhs
    assert_equal s(:lit, 2), exp.rhs
  end

  def test_if_expression
    exp = parse <<-RUBY
    if x
      y
    else
      z
    end
    RUBY

    assert_equal s(:call, nil, :x, s(:arglist)), exp.condition
    assert_equal s(:call, nil, :y, s(:arglist)), exp.then_clause
    assert_equal s(:call, nil, :z, s(:arglist)), exp.else_clause
  end

  def test_local_assignment
    exp = parse 'x = 1'

    assert_equal :x, exp.lhs
    assert_equal s(:lit, 1), exp.rhs
  end

  def test_instance_assignment
    exp = parse '@x = 1'

    assert_equal :@x, exp.lhs
    assert_equal s(:lit, 1), exp.rhs
  end

  def test_global_assignment
    exp = parse '$x = 1'

    assert_equal :$x, exp.lhs
    assert_equal s(:lit, 1), exp.rhs
  end

  def test_constant_assignment
    exp = parse 'X = 1'

    assert_equal :X, exp.lhs
    assert_equal s(:lit, 1), exp.rhs
  end

  def test_class_variable_assignment
    exp = parse '@@x = 1'

    assert_equal :@@x, exp.lhs
    assert_equal s(:lit, 1), exp.rhs
  end

  def test_method_def_name
    exp = parse <<-RUBY
    def x(y)
      z
      y
    end
    RUBY

    assert_equal :x, exp.method_name
  end

  def test_method_self_def_name
    exp = parse <<-RUBY
    def self.x(y)
      z
      y
    end
    RUBY

    assert_equal :x, exp.method_name
  end

  def test_method_def_body
    exp = parse <<-RUBY
    def x(y)
      z
      y
    end
    RUBY

    assert_equal s(:scope, s(:rlist, s(:call, nil, :z, s(:arglist)), s(:lvar, :y))), exp.body
  end

  def test_method_def_body_single_line
    exp = parse <<-RUBY
    def x(y)
      y
    end
    RUBY

    assert_equal s(:scope, s(:rlist, s(:lvar, :y))), exp.body
  end

  def test_class_body
    exp = parse <<-RUBY
    class X
      def y
      end
    end
    RUBY

    assert_equal s(:scope, s(:defn, :y, s(:args), s(:scope, s(:block, s(:nil))))), exp.body
  end

  def test_module_body
    exp = parse <<-RUBY
    module X
      def y
      end
    end
    RUBY

    assert_equal s(:scope, s(:defn, :y, s(:args), s(:scope, s(:block, s(:nil))))), exp.body
  end

  def test_class_name
    exp = parse 'class X < Y; end'

    assert_equal :X, exp.class_name
  end

  def test_parent_name
    exp = parse 'class X < Y; end'

    assert_equal s(:const, :Y), exp.parent_name
  end

  def test_module_name
    exp = parse 'module X; end'

    assert_equal :X, exp.module_name
  end

  def test_wrong_sexp_error
    exp = parse 'true ? false : true'

    assert_raise WrongSexpError do
      exp.method
    end
  end

  def test_zsuper_call
    exp = parse 'super'

    assert_equal :super, exp.method
    assert_equal s(:arglist), exp.arglist
    assert_equal s(), exp.args
  end

  def test_super_call
    exp = parse 'super 1'

    assert_equal :super, exp.method
    assert_equal s(:arglist, s(:lit, 1)), exp.arglist
    assert_equal s(s(:lit, 1)), exp.args
  end
end
