require 'brakeman/processors/lib/find_all_calls'

class CallIndexTests < Test::Unit::TestCase
  def setup
    @calls = [
      {:method => :hello, :target => :world, :call => {}, :nested => false },
      {:method => :goodbye, :target => :world, :call => {}, :nested => false  },
      {:method => :foo, :target => :world, :call => {}, :nested => false  },
      {:method => :foo, :target => :the_bar, :call => {}, :nested => false  },
      {:method => :foo, :target => :the_baz, :call => {}, :nested => false  },
      {:method => :do_it, :target => nil, :call => {}, :nested => false  },
      {:method => :do_it_now, :target => nil, :call => {}, :nested => false  },
    ]

    src = Brakeman::AliasProcessor.new.process RubyParser.new.parse <<-RUBY
      def x
        x.y.z(1)
        params[:x].y.z(2)
      end
    RUBY
    all_calls = Brakeman::FindAllCalls.new(Object.new)
    all_calls.process(src)
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
end
