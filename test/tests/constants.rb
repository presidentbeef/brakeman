class ConstantTests < Test::Unit::TestCase
  def assert_alias expected, original, full = false
    tracker = Brakeman::Tracker.new(nil)
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
end
