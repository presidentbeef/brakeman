class AliasProcessorTests < Test::Unit::TestCase
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


  def test_array_append
    assert_alias '[1, 2, 3]', <<-RUBY
      x = [1]
      x << 2 << 3
      x
    RUBY
  end

  def test_hash_index
    assert_alias "'You say goodbye, I say :hello'", <<-RUBY
      x = {:goodbye => "goodbye cruel world" }
      x[:hello] = "hello world"
      x.merge! :goodbye => "You say goodbye, I say :hello"
      x[:goodbye]
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

  def test_or_equal
    assert_alias '10', <<-RUBY
      x.y = 10
      x.y ||= "not this!"
      x.y
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

  def test_try_collapse
    assert_alias 'x.y', <<-RUBY
      z = x.try(:y)
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

  def test_simple_or_operation_compaction
    assert_alias "[0, ((1 || 2) || 3), (4 || 8)]", <<-RUBY
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

    tracker = Struct.new("FakeTracker", :options).new(:branch_limit => 4)

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
end
