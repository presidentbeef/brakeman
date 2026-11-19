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
    assert_found 2, :target => :world, :method => %r{oo}
  end

  def test_find_by_method
    assert_found 1, :method => :hello
  end

  def test_find_by_target
    assert_found 3, :target => :world
  end

  def test_find_by_target_regex
    # x.y.z
    assert_found 1, :targets => %r{^x\.y$}

    # x.y.z
    # params[].y.z
    assert_found 2, :targets => %r{\.y$}


    # the_bar.foo
    # the_baz.foo
    assert_found 2, :targets => %r{^the}, methods: [:foo, :goodbye]
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

  def test_find_by_more_targets
    assert_found 2, :target => [:world, :the_bar], :methods => [:foo]
  end

  def test_find_by_more_methods
    assert_found 2, :target => [:world], :methods => [:foo, :hello]
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

  def test_filter_by_chain
    assert_found 1, :target => [:params], :method => :z, :chained => true
    assert_found 1, :target => /^x$/, :method => :z, :chained => true
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

  def test_full_call
    xyz = @call_index.find_calls(target: :x, method: :z, chained: true).first
    xy = @call_index.find_calls(target: :x, method: :y, nested: true).first
    x = @call_index.find_calls(method: :x, nested: true).first
    thing = @call_index.find_calls(method: :do_a_thing).first

    # Full call for the call should be itself
    assert_equal thing, thing[:full_call]
    assert_equal xyz, xyz[:full_call]

    assert_equal xyz, xy[:full_call]
    assert_equal xyz, x[:full_call]
  end

  def index_calls src
    all_calls = Brakeman::FindAllCalls.new(Object.new)
    all_calls.process_source(RubyParser.new.parse(src), method: :x)
    Brakeman::CallIndex.new(all_calls.calls)
  end

  def test_block_as_target
    call_index = index_calls <<-RUBY
      def x
        things.map { |thing| inside(thing) }.flatten
      end
    RUBY

    assert_equal 1, call_index.find_calls(method: :flatten).length
    assert_equal 0, call_index.find_calls(target: :things, method: :map).length
    assert_equal 1, call_index.find_calls(
      target: :things, method: :map, nested: true
    ).length
    assert_equal 1, call_index.find_calls(target: nil, method: :inside).length
  end

  def test_block_in_block_call_arguments_as_target
    call_index = index_calls <<-RUBY
      def x
        outer(things.map { inside }) { }.last
      end
    RUBY

    assert_equal 0, call_index.find_calls(target: nil, method: :inside).length
    assert_equal 1, call_index.find_calls(
      target: nil, method: :inside, nested: true
    ).length
  end

  def test_non_call_targets
    call_index = index_calls <<-RUBY
      def x
        [in_array(1)].flatten
        "\#{in_string(1)}".strip
        (in_or(1) || []).first
        (y ? in_ternary(1) : []).first
        { key: in_hash(1) }.to_json
      end
    RUBY

    [:in_array, :in_string, :in_or, :in_ternary, :in_hash].each do |method|
      calls = call_index.find_calls(target: nil, method: method)
      assert_equal 1, calls.length, method
    end
  end

  def test_block_does_not_leak_full_call
    call_index = index_calls <<-RUBY
      def x
        outer(things.map { inside }.flatten, other.thing).last
      end
    RUBY

    inside = call_index.find_calls(target: nil, method: :inside).first
    thing = call_index.find_calls(
      target: :other, method: :thing, nested: true
    ).first

    refute_nil inside
    assert_equal inside, inside[:full_call]
    refute_equal inside, thing[:full_call]
  end

  def test_find_error
    assert_raises do
      @call_index.find_calls :target => nil, :methods => nil
    end
  end
end
