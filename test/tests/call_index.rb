require_relative '../test'
require 'brakeman/processors/lib/find_all_calls'

class CallIndexTests < Minitest::Test
  def setup
    @calls = [
      {:method => :hello, :target => :world, :call => {}, :nested => false },
      {:method => :goodbye, :target => :world, :call => {}, :nested => false  },
      {:method => :foo, :target => :world, :call => {}, :nested => false  },
      {:method => :foo, :target => :the_bar, :call => {}, :nested => false  },
      {:method => :foo, :target => :the_baz, :call => {}, :nested => false  },
      {:method => :do_it, :target => nil, :call => {}, :nested => false  },
      {:method => :do_it_now, :target => nil, :call => {}, :nested => false  },
      {:method => :with_target, :target => :blah, :call => {}, :nested => false  },
    ]

    meth_src = Brakeman::AliasProcessor.new.process RubyParser.new.parse <<-RUBY
      def x
        x.y.z(1)
        params[:x].y.z(2)
        third(second.thing(first.thing))
      end
    RUBY

    class_src = Brakeman::AliasProcessor.new.process RubyParser.new.parse <<-RUBY
    class A
      do_a_thing

      # Not indexed
      def x
        x.y.z(1)
        params[:x].y.z(2)
      end
    end
    RUBY
    all_calls = Brakeman::FindAllCalls.new(Object.new)
    all_calls.process_source(meth_src, method: :x)
    all_calls.process_source(class_src, class: :A)
    @calls += all_calls.calls

    @call_index = Brakeman::CallIndex.new(@calls)
  end

  def assert_found num, opts
    assert_equal num, @call_index.find_calls(opts).length
  end

  def test_find_by_method_regex
    assert_found 2, :method => %r{do_it(?:_now)?}
  end

  def test_find_by_method
    assert_found 1, :method => :hello
  end

  def test_find_by_target
    assert_found 3, :target => :world
  end

  def test_find_by_methods
    assert_found 5, :methods => [:foo, :hello, :goodbye]
  end

  def test_find_by_targets
    assert_found 4, :targets => [:world, :the_bar]
  end

  def test_find_by_target_and_method
    assert_found 1, :target => :the_bar, :method => :foo
  end

  def test_find_by_target_and_methods
    assert_found 2, :target => :world, :methods => [:foo, :hello]
  end

  def test_find_by_targets_and_method
    assert_found 2, :target => [:world, :the_bar], :methods => :foo
  end

  def test_find_by_no_target_and_method
    assert_found 1, :target => nil, :method => :do_it
    assert_found 0, :targets => nil, :method => :with_target
  end

  def test_find_by_no_target_and_methods
    assert_found 2, :target => nil, :method => [:do_it, :do_it_now]
  end

  def test_find_by_target_and_method_in_chain
    assert_found 0, :target => :x, :method => :z
    assert_found 1, :target => :x, :method => :z, :chained => true
  end

  def test_find_params_and_method_in_chain
    assert_found 0, :target => :params, :method => :z
    assert_found 1, :target => :params, :method => :z, :chained => true
  end

  def test_find_class_scope_call_by_method
    assert_found 1, :method => :do_a_thing
  end

  def test_parent_call
    first = @call_index.find_calls(method: :first, nested: true).first
    first_thing = @call_index.find_calls(target: :first, method: :thing).first
    second = @call_index.find_calls(method: :second, nested: true).first
    second_thing = @call_index.find_calls(target: :second, method: :thing).first
    third = @call_index.find_calls(target: nil, method: :third).first

    assert_equal second_thing, first_thing[:parent]
    assert_equal third, second_thing[:parent]

    assert_equal second_thing, first[:parent]
    assert_equal third, second[:parent]
    assert_nil third[:parent]
  end

  def test_find_error
    assert_raises do
      @call_index.find_calls :target => nil, :methods => nil
    end
  end
end
