class CallIndexTests < Test::Unit::TestCase
  def setup
    @calls = [
      {:method => :hello, :target => :world, :call => {} },
      {:method => :goodbye, :target => :world, :call => {} },
      {:method => :foo, :target => :world, :call => {} },
      {:method => :foo, :target => :the_bar, :call => {} },
      {:method => :foo, :target => :the_baz, :call => {} },
      {:method => :do_it, :target => nil, :call => {} },
      {:method => :do_it_now, :target => nil, :call => {} },
    ]
    @call_index = Brakeman::CallIndex.new(@calls)
  end

  def assert_found num, opts
    assert @call_index.find_calls(opts).length
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
end
