class AliasProcessorTests < Test::Unit::TestCase
  def assert_alias expected, original
    original_sexp = RubyParser.new.parse original
    expected_sexp = RubyParser.new.parse expected

    processed_sexp = Brakeman::AliasProcessor.new.process_safely original_sexp
    result = processed_sexp.last

    assert_equal expected_sexp, result
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
end
