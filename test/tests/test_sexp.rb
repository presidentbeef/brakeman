require 'brakeman/processors/base_processor'

class SexpTests < Test::Unit::TestCase
  def setup
    @ruby_parser = ::RubyParser
  end

  def parse string
    Brakeman::BaseProcessor.new(nil).process @ruby_parser.new.parse string
  end

  def test_method_call_with_no_args
    exp = parse "x.y"

    assert_equal s(:call, nil, :x), exp.target
    assert_equal :y, exp.method
    assert_equal s(), exp.args
    assert_equal s(:arglist), exp.arglist
    assert_nil exp.first_arg
    assert_nil exp.second_arg
    assert_nil exp.last_arg
  end

  def test_method_call_with_args
    exp = parse 'x.y(1, 2, 3)'

    assert_equal s(:call, nil, :x), exp.target
    assert_equal :y, exp.method
    assert_equal s(s(:lit, 1), s(:lit, 2), s(:lit, 3)), exp.args
    assert_equal s(:arglist, s(:lit, 1), s(:lit, 2), s(:lit, 3)), exp.arglist
    assert_equal s(:lit, 1), exp.first_arg
    assert_equal s(:lit, 2), exp.second_arg
    assert_equal s(:lit, 3), exp.last_arg
  end

  def test_method_call_no_target
    exp = parse 'x 1, 2, 3'

    assert_nil exp.target
    assert_equal :x, exp.method
    assert_equal s(s(:lit, 1), s(:lit, 2), s(:lit, 3)), exp.args
    assert_equal s(:arglist, s(:lit, 1), s(:lit, 2), s(:lit, 3)), exp.arglist
    assert_equal s(:lit, 1), exp.first_arg
    assert_equal s(:lit, 2), exp.second_arg
    assert_equal s(:lit, 3), exp.last_arg
  end

  def test_method_call_set_target
    exp = parse 'x.y'
    exp.target = :z

    assert_equal :z, exp.target
  end

  def test_method_call_set_arglist
    exp = parse 'x.y'
    exp.arglist = s(:arglist, s(:lit, 1), s(:lit, 2))

    assert_equal s(:lit, 1), exp.first_arg
    assert_equal s(:lit, 2), exp.second_arg
    assert_equal s(:lit, 2), exp.last_arg
    assert_equal s(:arglist, s(:lit, 1), s(:lit, 2)), exp.arglist
    assert_equal s(s(:lit, 1), s(:lit, 2)), exp.args
  end

  def test_method_call_set_args
    exp = parse "x.y"

    assert_equal s(), exp.args

    exp.set_args s(:lit, 1), s(:lit, 2)

    assert_equal s(s(:lit, 1), s(:lit, 2)), exp.args
    assert_equal s(:lit,1), exp.first_arg
    assert_equal s(:lit, 2), exp.second_arg
    assert_equal s(:lit, 2), exp.last_arg
  end

  def test_method_call_with_block
    exp = parse "x do |z|; blah z; end"
    block = exp.block
    call = exp.block_call
    args = exp.block_args

    assert_equal s(:call, nil, :x), call
    assert_equal s(:args, :z), args
    assert_equal s(:call, nil, :blah, s(:lvar, :z)), block
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

    assert_equal s(:call, nil, :x), exp.condition
    assert_equal s(:call, nil, :y), exp.then_clause
    assert_equal s(:call, nil, :z), exp.else_clause
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

    assert_equal s(s(:call, nil, :z), s(:lvar, :y)), exp.body
  end

  def test_method_def_body_single_line
    exp = parse <<-RUBY
    def x(y)
      y
    end
    RUBY

    assert_equal s(s(:lvar, :y)), exp.body
  end

  def test_class_body
    exp = parse <<-RUBY
    class X
      def y
      end
    end
    RUBY

    assert_equal s(s(:defn, :y, s(:args), s(:nil))), exp.body
  end

  def test_module_body
    exp = parse <<-RUBY
    module X
      def y
      end
    end
    RUBY

    assert_equal s(s(:defn, :y, s(:args), s(:nil))), exp.body
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

  def test_resbody_block
    #Ruby2Ruby has calls like this which need to be supported
    #for Brakeman::OutputProcessor
    exp = parse "begin; rescue; end"

    assert_nil exp.resbody.block
  end

  def test_lasgn
    #Ruby2Ruby has calls like this which need to be supported
    #for Brakeman::OutputProcessor
    exp = parse "blah; x = 1"

    assert_equal s(:lasgn, :x, s(:lit, 1)), exp.lasgn(true)
    assert_equal nil, exp.lasgn #Was deleted
  end

  def test_iasgn
    #Ruby2Ruby has calls like this which need to be supported
    #for Brakeman::OutputProcessor
    exp = parse "blah; @x = 1"

    assert_equal s(:iasgn, :@x, s(:lit, 1)), exp.iasgn(true)
    assert_equal nil, exp.iasgn #Was deleted
  end

  def test_each_arg
    exp = parse "blah 1, 2, 3"

    args = []
    exp.each_arg do |a|
      args << a.value
    end

    assert_equal [1,2,3], args
  end

  def test_each_arg!
    exp = parse "blah 1, 2"
    exp.each_arg! do |a|
      s(:lit, a.value + 1)
    end

    assert_equal s(:lit, 2), exp.first_arg
    assert_equal s(:lit, 3), exp.second_arg
  end

  # For performance reasons, Sexps cache their hash value. This was not being
  # invalidated on <<
  def test_hash_invalidation_on_push
    s = Sexp.new(:blah)
    s_hash = s.hash
    s << :blah

    assert_not_equal s_hash, s.hash
  end

  # Since Sexp is subclassed from Array, only changing the contents
  # of the Sexp actually change the hash value.
  def test_hash_invalidation_on_line_number_change
    s = Sexp.new(:blah).line(1)
    s_hash = s.hash
    s.line(10)

    assert_not_nil s.instance_variable_get(:@my_hash_value)
  end

  def test_sexp_line_set
    s = Sexp.new(:blah).line(10)
    assert_equal 10, s.line

    s.line = 100
    assert_equal 100, s.line

    s.line(0)
    assert_equal 0, s.line
  end

  def test_sexp_original_line_set
    s = Sexp.new(:blah)
    s.original_line = 10
    assert_equal 10, s.original_line

    s.original_line = 100
    assert_equal 100, s.original_line
  end
end
