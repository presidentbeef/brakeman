require_relative '../test'
require 'brakeman/processors/base_processor'

class SexpTests < Minitest::Test
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

  def test_method_call_set_method
    exp = parse "x.y"

    assert_equal :y, exp.method
    
    exp.method = :z

    assert_equal :z, exp.method
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

  def test_stabby_lambda_no_args
    exp = parse "->{ hi }"
    args = exp.block_args

    assert_equal s(:call, nil, :lambda), exp.block_call
    assert_equal s(:args), exp.block_args
    assert_equal s(:call, nil, :hi), exp.block
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

  def test_attribute_index_assignment
    exp = parse 'y[:x] = 1'

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

  def test_class_variable_declaration
    exp = parse '@@x = 1'

    assert_equal :cvdecl, exp.node_type
    assert_equal :@@x, exp.lhs
    assert_equal s(:lit, 1), exp.rhs
  end

  def test_class_variable_assignment
    exp = parse 'def x; @@a = 1; end'
    asgn = exp.last

    assert_equal :cvasgn, asgn.node_type
    assert_equal :@@a, asgn.lhs
    assert_equal s(:lit, 1), asgn.rhs
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

    assert_raises WrongSexpError do
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
    assert_nil exp.lasgn #Was deleted
  end

  def test_iasgn
    #Ruby2Ruby has calls like this which need to be supported
    #for Brakeman::OutputProcessor
    exp = parse "blah; @x = 1"

    assert_equal s(:iasgn, :@x, s(:lit, 1)), exp.iasgn(true)
    assert_nil exp.iasgn #Was deleted
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

    refute_equal s_hash, s.hash
  end

  # Since Sexp is subclassed from Array, only changing the contents
  # of the Sexp actually change the hash value.
  def test_hash_invalidation_on_line_number_change
    s = Sexp.new(:blah).line(1)
    s_hash = s.hash
    s.line(10)

    refute_nil s.instance_variable_get(:@my_hash_value)
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

  def test_combine_and_or_depth
    e = Sexp.new(:lit, 0)

    3.times do |i|
      e = e.combine(Sexp.new(:lit, i))
    end

    assert_equal s(:or, s(:or, s(:or, s(:lit, 0), s(:lit, 0)), s(:lit, 1)), s(:lit, 2)), e
    assert_equal 3, e.or_depth
  end

  def test_inspect_recursive
    s = Sexp.new(:s)
    s << s
    assert_equal "s(:s, s(...))", s.inspect
  end

  def test_value
    assert_equal 1, s(:lit, 1).value
    assert_nil s(:blah).value
    assert_raises do
      s(:blah, 1, 2).value
    end
  end

  def test_call_chain
    s = RubyParser.new.parse "w.new.x.y(:stuff).z.to_s(1)"
    cc = [:w, :new, :x, :y, :z, :to_s]

    assert_equal cc, s.call_chain
  end

  def test_short_call_chain
    s = Sexp.new(:call, nil, :x)

    assert_equal [:x], s.call_chain
  end

  def test_local_call_chain
    s = Sexp.new(:call, s(:lvar, :z), :x)

    assert_equal [:x], s.call_chain
  end

  def test_body_list_set
    exp = parse <<-RUBY
    def x(y)
      z
      y
    end
    RUBY

    exp2 = parse <<-RUBY
    def z
      z
    end
    RUBY

    assert_equal s(:rlist, s(:call, nil, :z)), exp2.body_list

    exp.body = exp2.body_list

    assert_equal s(s(:call, nil, :z)), exp.body
  end
end
