require_relative '../test'

class AliasProcessorTests < Minitest::Test
  def assert_alias expected, original, full = false
    original_sexp = RubyParser.new.parse original
    expected_sexp = RubyParser.new.parse expected
    processed_sexp = Brakeman::AliasProcessor.new.process_safely original_sexp

    if full
      assert_equal expected_sexp, processed_sexp
    else
      assert_equal expected_sexp, processed_sexp.last
    end
  end

  def assert_output input, output
    assert_alias output, input, true
  end

  def test_addition
    assert_alias '10', <<-RUBY
      x = 1 + 2 + 3
      x += 4
      x
    RUBY
  end

  def test_simple_math
    assert_alias '42', <<-RUBY
      x = 8 * 5
      y = 32 / 8
      y -= 2
      x += y
      x
    RUBY
  end

  def test_divide_by_zero
    assert_alias '1 / 0', <<-RUBY
    x = 1 / 0
    x
    RUBY
  end

  def test_infinity
    e = RubyParser.new.parse "x = 1.0 / 0; x"
    a = Brakeman::AliasProcessor.new.process_safely e

    assert_equal Sexp.new(:lit, 1.0 / 0), a.last
  end

  def test_concatentation
    assert_alias "'Hello world!'", <<-RUBY
      x = "Hello"
      y = x + " "
      z = y + "world!"
      z
    RUBY
  end

  def test_string_append
    assert_alias "'hello world'", <<-RUBY
      x = ""
      x << "hello" << " " << "world"
      x
    RUBY
  end

  def test_string_new_append
    assert_alias "'hello world'", <<-RUBY
      x = String.new
      x << "hello" << " " << "world"
      x
    RUBY
  end

  def test_string_append_call
    assert_alias "'hello ' << params[:x]", <<-RUBY
    x = ""
    x << 'hello ' << params[:x]
    x
    RUBY
  end

  def test_string_interp_concat
    assert_alias '"#{y}\nthing"', <<-'RUBY'
    x = "#{y}\n"
    x << "thing"
    x
    RUBY
  end

  def test_string_concat_interp
    assert_alias '"hello\n#{world}"', <<-'RUBY'
    x = ""
    x << "hello"
    x << "\n#{world}"
    x
    RUBY
  end

  def test_array_index
    assert_alias "'cookie'", <<-RUBY
      dessert = ["fruit", "pie", "ice cream"]
      dessert << "cookie"
      dessert[1] = "cake"
      dessert[1]
      index = 2
      index = index + 1
      dessert[index]
    RUBY
  end

  def test_array_negative_index
    assert_alias "'ice cream'", <<-RUBY
      dessert = ["fruit", "pie", "ice cream"]
      dessert << "cookie"
      dessert[1] = "cake"
      dessert[1]
      index = -3
      index = 1 + index
      dessert[index]
    RUBY
  end

  def test_array_fetch
    assert_alias '3', <<-RUBY
    x = [1, 2, 3]
    x.fetch(2)
    RUBY
  end

  def test_array_fetch_unknown_literal
    assert_alias ':BRAKEMAN_SAFE_LITERAL', <<-RUBY
    x = [1, 2, 3]
    y = x.fetch(z)
    y
    RUBY
  end

  def test_array_index_unknown_literal
    assert_alias ':BRAKEMAN_SAFE_LITERAL', <<-RUBY
    x = [1, 2, 3][y]
    x
    RUBY
  end

  def test_array_append
    assert_alias '[1, 2, 3]', <<-RUBY
      x = [1]
      x << 2 << 3
      x
    RUBY
  end

  def test_array_new_append
    assert_alias '[1, 2, 3]', <<-RUBY
      x = Array.new
      x << 1 << 2 << 3
      x
    RUBY
  end

  def test_array_new_init_append
    assert_alias '[1, 2, 3]', <<-RUBY
      x = Array.new(1)
      x << 2 << 3
      x
    RUBY
  end

  def test_array_push
    assert_alias '[1, 2, 3]', <<-RUBY
      x = [1]
      x.push(2)
      x.push(3)
      x
    RUBY
  end

  def test_array_detect
    assert_alias ':BRAKEMAN_SAFE_LITERAL', <<-RUBY
      x = [1,2,3].detect { |x| x.odd? }
      x
    RUBY
  end

  def test_array_first
    assert_alias '1', <<-RUBY
      x = [1, 2, 3]
      y = x.first
      y
    RUBY
  end

  def test_array_plus_equals
    assert_alias '[1, 2, 3]', <<-RUBY
    x = [1]
    x += [2, 3]
    x
    RUBY
  end

  def test_array_plus
    assert_alias '[1, 2, 3]', <<-RUBY
    x = [1]
    y = x + [2, 3]
    y
    RUBY
  end

  def test_array_plus_no_lines
    a1 = s(:array, s(:lit, 1))
    a2 = s(:array, s(:lit, 2))
    joined = Brakeman::AliasProcessor.new.join_arrays(a1, a2)
    expected = s(:array,
                 s(:lit, 1),
                 s(:lit, 2))

    assert_equal expected, joined
  end

  def test_hash_index
    assert_alias "'You say goodbye, I say :hello'", <<-RUBY
      x = {:goodbye => "goodbye cruel world" }
      x[:hello] = "hello world"
      x.merge! :goodbye => "You say goodbye, I say :hello"
      x[:goodbye]
    RUBY
  end

  def test_hash_new_index
    assert_alias "'You say goodbye, I say :hello'", <<-RUBY
      x = Hash.new
      x[:hello] = "hello world"
      x.merge! :goodbye => "You say goodbye, I say :hello"
      x[:goodbye]
    RUBY
  end

  def test_hash_fetch
    assert_alias '1', <<-RUBY
      x = { a: 0, b: 1, c: 3 }
      x.fetch(:b)
    RUBY
  end

  def test_hash_fetch_unknown_literal
    assert_alias ':BRAKEMAN_SAFE_LITERAL', <<-RUBY
      x = { a: 0, b: 1, c: 3 }
      x.fetch(:z)
    RUBY
  end

  def test_hash_update
    assert_alias "2", <<-RUBY
      @foo = {
        :denominator => 0
      }

      @foo[:denominator] += 2

      x = @foo[:denominator]
      x
    RUBY
  end

  def test_hash_values
    assert_alias '[1, 2, 3]', <<-RUBY
      h = { a: 1, b: 2, c: 3 }
      h.values
    RUBY
  end

  def test_hash_values_at
    assert_alias '[1, 2]', <<-RUBY
      h = { a: 1, b: 2, c: 3 }
      h.values_at(:a, :b)
    RUBY
  end

  def test_hash_values_at_missing
    assert_alias '{ a: 1, b: 2, c: x }.values_at(:a, :b, :z)', <<-RUBY
      h = { a: 1, b: 2, c: x }
      h.values_at(:a, :b, :z)
    RUBY
  end

  def test_hash_values_at_missing_safe
    assert_alias '[1, 2, :BRAKEMAN_SAFE_LITERAL]', <<-RUBY
      h = { a: 1, b: 2, c: 3 }
      h.values_at(:a, :b, :z)
    RUBY
  end

  def test_hash_double_splat
    assert_alias "1", <<-RUBY
      a = { a: 1, b: "two", c: :three }
      b = { **a, d: 4 }
      b[:a]
    RUBY
  end

  def test_hash_shorthand_syntax
    assert_alias '2', <<-RUBY
      a = 1
      b = 2
      h = { a:, b: }
      h[:b]
    RUBY
  end

  def test_hash_shorthand_syntax_unknown_value
    assert_alias 'b', <<-RUBY
      h = { a:, b:, c: 1 }
      h[:b]
    RUBY
  end

  def test_hash_shorthand_syntax_mix
    assert_alias '3', <<-RUBY
      a = 1
      h = { a:, b:, c: 3 }
      h[:c]
    RUBY
  end

  def test_splat_array_args
    assert_alias 'x(1, b, :c)', <<-RUBY
      a = b
      args = [1, a, :c]
      x(*args)
    RUBY
  end

  def test_obvious_if
    assert_alias "'Yes!'", <<-RUBY
      condition = true

      if condition
        x = "Yes!"
      else
        x = "No!"
      end

      x
    RUBY
  end

  def test_skip_obvious_if
    assert_output <<-INPUT, <<-OUTPUT
      condition = false

      if condition
        x = true
      else
        x = false
      end
      INPUT
      condition = false

      if false
      else
        x = false
      end
      OUTPUT
  end

  def test_skip_rails_env_test
    assert_alias "'No!'", <<-RUBY
      if Rails.env.test?
        x = "Yes!"
      else
        x = "No!"
      end

      x
    RUBY
  end

  def test_if
    assert_alias "'Awesome!' or 'Else awesome!'", <<-RUBY
      if something
        x = "Awesome!"
      elsif something_else
        x = "Else awesome!"
      end

      x
    RUBY
  end

  def test_if_in_when
    # Just testing that `if` inside a `when` doesn't cause an error
    # https://github.com/presidentbeef/brakeman/issues/1743
    assert_alias '1', <<-RUBY
    case something
    when (if a then b else c end) then 1
    end

    1
    RUBY
  end

  def test_or_equal
    assert_alias '10', <<-RUBY
      x.y = 10
      x.y ||= "not this!"
      x.y
    RUBY
  end

  def test_safe_or_equal
    assert_alias '10', <<-RUBY
      x&.y ||= 10
      x&.y ||= "not this!"
      x&.y
    RUBY
  end

  def test_unknown_hash
    assert_alias '1', <<-RUBY
      some_hash[:x] = 1
      some_hash[:x]
    RUBY
  end

  def test_global
    assert_alias '1', <<-RUBY
      $x = 1
      $x
    RUBY
  end

  def test_class_var
    assert_alias '1', <<-RUBY
      @@x = 1
      @@x
    RUBY
  end

  def test_constant
    assert_alias '1', <<-RUBY
      X = 1
      X
    RUBY
  end

  def test_addition_chained
    assert_alias 'y + 5', <<-RUBY
      x = y + 2 + 3
      x
    RUBY
  end

  def test_send_collapse
    assert_alias 'x.y(1)', <<-RUBY
      z = x.send(:y, 1)
      z
    RUBY
  end

  def test_send_collapse_with_no_target
    assert_alias 'y(1)', <<-RUBY
      x = send(:y, 1)
      x
    RUBY
  end

  def test_safe_send_collapse
    assert_alias 'x.y(1)', <<-RUBY
      z = x&.send(:y, 1)
      z
    RUBY
  end

  def test_safe___send__
    assert_alias 'X.y(:z)', <<-RUBY
    a = X.__send__(:y, :z)
    a
    RUBY
  end

  def test_try_collapse
    assert_alias 'x.y', <<-RUBY
      z = x.try(:y)
      z
    RUBY
  end

  def test_try_symbol_to_proc_collapse
    assert_alias 'x.y', <<-RUBY
      z = x.try(&:y)
      z
    RUBY
  end

  def test_multiple_assignments_in_if
    assert_alias "1 or 4", <<-RUBY
    x = 1

    if y
      x = 2
      x = 3
      x = 4
    end

    x
    RUBY
  end

  def test_assignments_both_branches
    assert_alias "'1234' or 6", <<-RUBY
    if y
      x = '1'
      x += '2'
      x += '3'
      x += '4'
    else
      x = 5
      x = 6
    end

    x
    RUBY
  end

  def test_assignments_in_forced_branch
    assert_alias "4", <<-RUBY
    x = 1

    if true
      x = 2
      x = 3
      x = 4
    else
      x = 5
      x = 6
    end

    x
    RUBY
  end

  def test_assignments_inside_branch_are_isolated
    assert_alias "5", <<-RUBY
    x = 1
    if something
      x = 2
      x = 3
    else
      x = 4
      x = 5
      y = x
    end

    y
    RUBY
  end

  def test_simple_if_branch_replacement
    assert_alias "1", <<-RUBY
    x = 1

    y = true ? x : z
    y
    RUBY
  end

  def test_assignment_in_equality_forced_branch
    assert_alias ':yes', <<-RUBY
      x = 1
      y = nil

      if x == 1
        y = :yes
      else
        y = :no
      end

      y
    RUBY
  end

  def test_simple_or_operation_compaction
    assert_alias "[0, 4, (4 || 8)]", <<-RUBY
    x = 1

    if z
      x += 1
      y = 2
      w = 10
    else
      x += 2
      y = 4
      w = 5
    end

    w = w * 0
    y = y * 2

    [w, x, y]
    RUBY
  end

  def test_assignment_of_simple_if_expression
    assert_alias "1 or 2", <<-RUBY
    x = (test ? 1 : 2)
    x
    RUBY
  end

  def test_assignment_of_forced_if_expression
    assert_alias "1", <<-RUBY
    x = (true ? 1 : 2)
    x
    RUBY
  end

  def test_default_branch_limit_5
    assert_alias "(6 or 7) or 8", <<-RUBY
    x = 0

    if something
      x = 1
    else
      x = 2
    end

    x = 3 unless this
    x = 4 if that

    if another_thing
      x = 5
    else
      x = 6
    end

    x = 7 if getting_crazy
    x = 8 if so_crazy

    x
    RUBY
  end

  def test_default_branch_limit_not_reached
    assert_alias "(((1 or 2) or 3) or 4)", <<-RUBY
    x = 1

    if something
      x = 2
    else
      x = 3
    end

    x = 4 unless this

    x
    RUBY
  end

  def test_default_branch_limit_before_reset_with_option
    expected_y = RubyParser.new.parse "((((0 or 1) or 2) or 3) or 4)"
    expected_x = RubyParser.new.parse "5 or 6"
    original_sexp = RubyParser.new.parse <<-RUBY
    x = 0

    if something
      x = 1
    else
      x = 2
    end

    if another_thing
      x = 3
    else
      x = 4
    end

    y = x

    x = 5 if getting_crazy
    x = 6 if so_crazy

    [x, y]
    RUBY

    tracker = BrakemanTester.new_tracker(:branch_limit => 4)

    assert_equal 4, tracker.options[:branch_limit]

    processed_sexp = Brakeman::AliasProcessor.new(tracker).process_safely original_sexp
    result = processed_sexp.last

    assert_equal expected_x, result[1]
    assert_equal expected_y, result[2]
  end

  def test_simple_block_args
    assert_alias '1', <<-RUBY
    y = 1

    x do |y|
      y = 2
    end

    y
    RUBY
  end

  def test_block_arg_assignment
    assert_alias '1 + z', <<-RUBY
    y = 1

    blah do |y = 3, x = 2|
      y = 2
      z = x
    end

    y + z
    RUBY
  end

  def test_block_arg_destructing
    assert_alias '1', <<-RUBY
    y = 1

    blah do |(x, y)|
      y = 2
    end

    y
    RUBY
  end

  def test_block_args_trailing_comma
    # Just testing it doesn't blow up
    assert_alias '1', <<-RUBY
    blah do |x,|
    end

    1
    RUBY
  end

  def test_block_with_local
    assert_output <<-INPUT, <<-OUTPUT
      def a
        if b
          c = nil
          ds.each do |d|
            e = T.new
            c = e.map
          end

          r("f" + c.name)
        else
          g
        end
      end
    INPUT
      def a
        if b
          c = nil
          ds.each do |d|
            e = T.new
            c = T.new.map
          end

          r("f" + T.new.map.name)
        else
          g
        end
      end
    OUTPUT
  end

  def test_shadowed_block_arg
    assert_output <<-INPUT, <<-OUTPUT
      def a
        y = 1
        x do |w; y, z|
          y = 2
        end
        puts y
      end
    INPUT
      def a
        y = 1
        x do |w; y, z|
          y = 2
        end
        puts 1
      end
    OUTPUT
  end

  def test_block_in_class_scope
    # Make sure blocks in class do not mess up instance variable scope
    # for subsequent methods
    assert_output <<-INPUT, <<-OUTPUT
      class A
        x do
          @a = 1
        end

        def b
          @a
        end
      end
    INPUT
      class A
        x do
          @a = 1
        end

        def b
          @a
        end
      end
    OUTPUT
  end

  def test_instance_method_scope_in_block
    # Make sure instance variables set inside blocks are set at the method
    # scope
    assert_output <<-INPUT, <<-OUTPUT
      class A
        def b
          x do
            @a = 1
          end

          @a
        end
      end
    INPUT
      class A
        def b
          x do
            @a = 1
          end

          1
        end
      end
    OUTPUT
  end

  def test_instance_method_scope_in_if_with_blocks
    # Make sure instance variables set inside if expressions are set at the
    # method scope after being combined
    assert_output <<-INPUT, <<-OUTPUT
      class A
        def b
          if something
            x do
              @a = 1
            end
          else
            y do
              @a = 2
            end
          end

          @a
        end
      end
    INPUT
      class A
        def b
          if something
            x do
              @a = 1
            end
          else
            y do
              @a = 2
            end
          end

          (1 or 2)
        end
      end
    OUTPUT
  end

  def test_branch_env_is_closed_after_if_statement
    assert_output <<-'INPUT', <<-'OUTPUT'
      def a
        if b
          return unless c # this was causing problems
          @d = D.find(1)
          @d
        end
      end
    INPUT
      def a
        if b
          return unless c
          @d = D.find(1)
          D.find(1)
       end
      end
    OUTPUT
  end

  def test_no_branch_for_plus_equals_with_string
    assert_alias '"abc"', <<-INPUT
      x = "a"
      x += "b" if something
      x += "c" if something_else
      x
    INPUT
  end

  def test_no_branch_for_plus_equals_with_string_in_ivar
    assert_alias '"abc"', <<-INPUT
      @x = "a"
      @x += "b" if something
      @x += "c" if something_else
      @x
    INPUT
  end

  #We could do better, but this prevents some Sexp explosions and retains
  #information about the values
  def test_no_branch_for_plus_equals_with_interpolated_string
    assert_alias '"a" + "#{b}" + "c"', <<-'INPUT'
      x = "a"
      x += "#{b}" if something
      x += "c" if something_else
      x
    INPUT
  end

  #Unfortunate to go to this behavior which loses information
  #but I can't think of a scenario in which the several integers
  #in ORs would be handled right anyway
  def test_no_branch_for_plus_equals_with_number
    assert_alias '6', <<-INPUT
      x = 1
      x += 2 if something
      x += 3 if something_else
      x
    INPUT
  end

  def test_keywords_in_blocks
    assert_output <<-'INPUT', <<-'OUTPUT'
    x do |y: 1, z: "2"|
      puts y, z
    end
    INPUT
    x do |y: 1, z: "2"|
      puts 1, "2"
    end
    OUTPUT
  end

  def test_multiple_assignment
    assert_output <<-INPUT, <<-OUTPUT
    x, $y = 1, 2
    x
    $y
    INPUT
    x, $y = 1, 2
    1
    2
    OUTPUT
  end

  def test_chained_assignment
    assert_alias '1', <<-INPUT
    x = y = 1
    x
    INPUT

    assert_alias '1', <<-INPUT
    @x = @y = 1
    @x
    INPUT

    assert_alias '1', <<-INPUT
    $x = $y = 1
    $x
    INPUT

    assert_alias '1', <<-INPUT
    X = Y = 1
    X
    INPUT

    assert_alias '1', <<-INPUT
    @@x = @@y = 1
    @@x
    INPUT

    assert_alias '1', <<-INPUT
    w.x = x.y = 1
    w.x
    INPUT

    assert_alias '5', <<-INPUT
    A = @b = @@c = $D = e.f = 1
    z = A + @b + @@c + $D + e.f
    z
    INPUT
  end

  def test_branch_with_self_assign_target
    assert_alias 'a.w.y', <<-INPUT
    x = a
    x = x.w if thing
    x = x.y if other_thing
    x
    INPUT
  end

  def test_splat_assign
    assert_alias '[[3, 4]]', <<-INPUT
    x, y, *z = [1, 2, [3, 4]]
    z
    INPUT

    assert_alias '[3, 4]', <<-INPUT
    x, y, *z = 1, 2, 3, 4
    z
    INPUT

    assert_alias '[2, 3]', <<-INPUT
    a, *b, c = 1, 2, 3, 4
    b
    INPUT

    assert_alias '[2]', <<-INPUT
    a, *b, c, d = 1, 2, 3, 4
    b
    INPUT

    assert_alias '[]', <<-INPUT
    a, *b, c, d = 1, 2, 3
    b
    INPUT

    assert_alias '[[]]', <<-INPUT
    *a = [[]]
    a
    INPUT
  end

  def test_presence_in_all_literals
    assert_alias "'1'", <<-INPUT
    x = '1'.presence_in ['1', '2', '3']
    x
    INPUT
  end

  def test_presence_in_unknown
    assert_alias ':BRAKEMAN_SAFE_LITERAL', <<-INPUT
    x = y.presence_in ['1', '2', '3']
    x
    INPUT
  end

  def test_branch_in_array
    assert_alias 'x', <<-INPUT
    if x.in? [1,2,3]
      stuff
    end

    x
    INPUT

    assert_output <<-INPUT, <<-OUTPUT
    if x.in? [1,2,3]
      y = x + 2
      p y
    end

    x
    INPUT
    if x.in? [1,2,3]
      y = :BRAKEMAN_SAFE_LITERAL
      p :BRAKEMAN_SAFE_LITERAL
    end

    x
    OUTPUT

    assert_output <<-INPUT, <<-OUTPUT
    x = params[:x]
    if x.in? ['a','b']
      User.send x
    end

    x
    INPUT
    x = params[:x]
    if params[:x].in? ['a','b']
      User.BRAKEMAN_SAFE_LITERAL
    end

    params[:x]
    OUTPUT
  end

  def test_branch_array_include
    assert_alias 'x', <<-INPUT
    if [1,2,3].include? x
      stuff
    end

    x
    INPUT

    assert_output <<-INPUT, <<-OUTPUT
    if [1,2,3].include? x
      y = x + 2
      p y
    end

    x
    INPUT
    if [1,2,3].include? x
      y = :BRAKEMAN_SAFE_LITERAL
      p :BRAKEMAN_SAFE_LITERAL
    end

    x
    OUTPUT

    assert_output <<-INPUT, <<-OUTPUT
    x = params[:x].presence
    if ['a','b'].include? x
      User.send x
    end

    x
    INPUT
    x = params[:x]
    if ['a','b'].include? params[:x]
      User.BRAKEMAN_SAFE_LITERAL
    end

    params[:x]
    OUTPUT
  end

  def test_branch_array_include_return
    assert_output <<-INPUT, <<-OUTPUT
    return unless ['a', 'b'].include? x
    x
    INPUT
    return unless ['a', 'b'].include? x
    :BRAKEMAN_SAFE_LITERAL
    OUTPUT
  end

  def test_branch_array_include_return_more
    assert_output <<-INPUT, <<-OUTPUT
    x = params[:thing].first
    y = ['a', 'b']
    unless y.include? x
      do_stuff
      return
    end
    x
    INPUT
    x = params[:thing].first
    y = ['a', 'b']
    unless ['a', 'b'].include? params[:thing].first
      do_stuff
      return
    end
    :BRAKEMAN_SAFE_LITERAL
    OUTPUT
  end

  def test_branch_array_include_fail
    assert_output <<-INPUT, <<-OUTPUT
    fail unless ['a', 'b'].include? x
    x
    INPUT
    fail unless ['a', 'b'].include? x
    :BRAKEMAN_SAFE_LITERAL
    OUTPUT
  end

  def test_branch_array_include_raise
    assert_output <<-INPUT, <<-OUTPUT
    raise Z unless ['a', 'b'].include? x
    x
    INPUT
    raise Z unless ['a', 'b'].include? x
    :BRAKEMAN_SAFE_LITERAL
    OUTPUT
  end

  def test_equality_condition_in_branch
    # Expect `x` inside true branch to be `1`
    # but elsewhere unknown
    assert_output <<-INPUT, <<-OUTPUT
      if x == 1
        a(x)
      else
        b(x)
      end

      c(x)
    INPUT
      if x == 1
        a(1)
      else
        b(x)
      end

      c(x)
    OUTPUT
  end

  def test_case_basic
    assert_output <<-INPUT, <<-OUTPUT
      z = 3

      case x
      when 1
        y = 1
      when 2
        y = 2
      else
        z = z + 1
        y = z
      end

      p y
    INPUT
      z = 3

      case x
      when 1
        y = 1
      when 2
        y = 2
      else
        z = 4
        y = 4
      end

      p(((1 or 2) or 4))
    OUTPUT
  end

  def test_case_assignment
    assert_output <<-INPUT, <<-OUTPUT
      y = case x
      when 1
        1
      when 2
        2
      else
        3
      end

      p y
    INPUT
      y = case x
      when 1
        1
      when 2
        2
      else
        3
      end

      p(((1 or 2) or 3))
    OUTPUT
  end

  def test_case_value
    assert_output <<-INPUT, <<-OUTPUT
      y = case x
      when 1
        x + 1
      when 2
        x + 2
      else
        x + 3
      end

      p y
    INPUT
      y = case x
      when 1
        2
      when 2
        4
      else
        x + 3
      end

      p(((2 or 4) or (x + 3)))
    OUTPUT
  end

  def test_case_value_params
    assert_output <<-INPUT, <<-OUTPUT
      case params[:x]
      when 1
        y(params[:x])
      when 2
        z(params[:x])
      end
    INPUT
      case params[:x]
      when 1
        y(1)
      when 2
        z(2)
      end
    OUTPUT
  end

  def test_case_list
    assert_output <<-INPUT, <<-OUTPUT
      case y
      when :a, :b, :c
        something(y)
      end
    INPUT
      case y
      when :a, :b, :c
        something(:BRAKEMAN_SAFE_LITERAL)
      end
    OUTPUT
  end

  def test_case_splat
    assert_output <<-INPUT, <<-OUTPUT
      x = [1, 2, 3]

      case y
      when *x
        something(y)
      end
    INPUT
      x = [1, 2, 3]

      case y
      when *[1, 2, 3]
        something(:BRAKEMAN_SAFE_LITERAL)
      end
    OUTPUT
  end

  def test_less_copying_of_arrays_and_hashes
    assert_output <<-'INPUT', <<-'OUTPUT'
      x = {}
      x[y] = x[z]
      x[z] = x[q] + x[y]
      x[g] = x[z] + x[y]
    INPUT
      x = {}
      x[y] = x[z]
      x[z] = x[q] + x[z]
      x[g] = x[q] + x[z] + x[z]
    OUTPUT
  end

  def test_less_copying_of_arrays_and_hashes_and_params
    assert_output <<-INPUT, <<-OUTPUT
      x = params
      x.symbolize_keys[:x]
    INPUT
      x = params
      params.symbolize_keys[:x]
    OUTPUT
  end

  def test_array_destructuring_asgn
    assert_alias "1", <<-INPUT
    x = [:a, [0, 1], :b, :c]
    a, (x, y), b, c = x
    y
    INPUT
  end

  def test_array_join_to_interpolation
    assert_alias '"blah 1 #{thing} else"', <<-'INPUT'
      x = ["blah", 1, thing, "else"].join(' ')
      x
    INPUT
  end

  def test_array_join_no_separater
    assert_alias '"blah1#{thing}else"', <<-'INPUT'
      x = ["blah", 1, thing, "else"].join
      x
    INPUT

    assert_alias '"#{this}#{that}#{annd}#{uh}"', <<-'INPUT'
      x = [this, that, annd, uh].join
      x
    INPUT
  end

  def test_array_join_lots_of_interp
    assert_alias '"blah:#{this}:#{that}:end"', <<-'INPUT'
      x = ["blah", this, that, "end"].join(':')
      x
    INPUT

    assert_alias '"#{this}!#{that}!#{annd}!#{uh}"', <<-'INPUT'
      x = [this, that, annd, uh].join('!')
      x
    INPUT
  end

  def test_array_star_join
    assert_alias '"a b 1"', <<-'INPUT'
      a = :a
      b = 'b'
      c = 1
      [a, b, c] * ' '
    INPUT
  end

  def test_array_join_line_numbers
    # Test that line numbers are set for all parts of a joined string
    original_sexp = RubyParser.new.parse "z = [x, 1].join(' ')"
    processed_sexp = Brakeman::AliasProcessor.new.process_safely(original_sexp)

    assert_equal s(:lasgn, :z, s(:dstr, "", s(:evstr, s(:call, nil, :x)), s(:str, " 1"))), processed_sexp
    assert_equal 1, processed_sexp[2].line
    assert_equal 1, processed_sexp[2][2].line
    assert_equal 1, processed_sexp[2][2][1].line
    assert_equal 1, processed_sexp[2][3].line
  end

  def test_array_join_single_value
    assert_alias "'hello'", <<-INPUT
      x = ["hello"].join(' ')
      x
    INPUT
  end

  def test_array_join_empty_array
    assert_alias "''", <<-INPUT
      x = [].join(' ')
      x
    INPUT
  end

  def test_ignore_freeze
    assert_alias "blah", <<-INPUT
    x = blah.freeze
    x
    INPUT
  end

  def test_ignore_dup
    assert_alias "blah", <<-INPUT
    x = blah.dup
    x
    INPUT
  end

  def test_ignore_presence
    assert_alias "blah", <<-INPUT
    x = blah.presence
    x
    INPUT
  end

  def test_join_incompatible_strings
    # Fails to completely join strings
    # because of encoding issues, but that's better
    # than raising an exception
    assert_alias '"P1\xC0f\xB88\x01" + "\xcd\x80"', <<-'INPUT'
    # -*- coding: binary -*-
    a = "\x50" + "\x31\xc0" + "\x66\xb8\x38\x01" + "\xcd\x80"
    a
    INPUT
  end

  def test_join_very_long_string
    long_string = "*" * 50

    assert_alias "#{long_string.inspect}", <<-INPUT
    a = #{long_string.inspect} + '1'
    a
    INPUT
  end

  def test_bang_bang
    assert_alias "true or false", <<-INPUT
    x = !!a
    x
    INPUT
  end

  def test_join_item_works_with_nil_item
    assert_nothing_raised do
      Brakeman::AliasProcessor.new.join_item(nil, "something")
    end
  end

  def test_alias_processor_failure
    assert_raises do
      Brakeman::AliasProcessor.new.process s(:block, s(:attrasgn, s(:call, nil, :x), :"[]!", s(:lit, 1), s(:lit, 2)))
    end

    # Does not raise because the error is caught and handled by the Tracker
    assert Brakeman::AliasProcessor.new(BrakemanTester.new_tracker).process s(:block, s(:attrasgn, s(:call, nil, :x), :"[]!", s(:lit, 1), s(:lit, 2)))
  end
end
