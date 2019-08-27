require_relative "../test"
require "brakeman/tracker/class_collection"

class TestClassCollection < Minitest::Test
  def new_model name = @names.pop
    Brakeman::Model.new(name, nil, nil, nil, BrakemanTester.new_tracker)
  end

  def setup
    @collection = Brakeman::ClassCollection.new
    @names = ('A'..'Z').map(&:to_sym)
  end

  def test_set_and_get
    m = new_model
    @collection[m.name] = m

    assert_equal m, @collection[m.name]
  end

  def test_get_strict
    m = new_model(:"A::B")
    @collection[m.name] = m

    assert_equal m, @collection[m.name, :strict]
    assert_nil @collection[:B, :strict]
  end

  def test_shovel
    m = new_model
    @collection << m

    assert_equal m, @collection[m.name]
  end

  def test_delete
    m = new_model
    @collection << m

    assert_equal m, @collection[m.name]

    @collection.delete m.name

    assert_nil @collection[m.name]
    assert @collection.empty?
  end

  def test_delete_if
    m1 = new_model
    m2 = new_model
    @collection << m1
    @collection << m2

    assert_equal 2, @collection.length

    @collection.delete_if do |klass|
      klass == m2
    end

    assert_equal 1, @collection.length
    assert_nil @collection[m2.name]
    assert_equal m1, @collection[m1.name]
  end

  def test_any?
    refute @collection.any?

    @collection << new_model

    assert @collection.any?

    assert_raises ArgumentError do
      @collection.any? do
      end
    end
  end

  def test_empty?
    assert @collection.empty?

    @collection << new_model

    refute @collection.empty?
  end
end

class TestClassName < Minitest::Test

  def test_sanity_equality
    c = Brakeman::ClassName.new(:Thing)
    d = Brakeman::ClassName.new(:Thing)

    assert_equal c, c
    assert_equal c, d
  end

  def test_equality
    c = Brakeman::ClassName.new(:Thing)
    d = Brakeman::ClassName.new(:'A::B::C::Thing')
    e = Brakeman::ClassName.new(:'C::Thing')

    assert_equal c, d
    assert_equal d, c
    assert_equal c, e
    assert_equal d, e
  end

  def test_collection
    x = Brakeman::ClassCollection.new
    c = Brakeman::Model.new(:Thing, nil, nil, nil, BrakemanTester.new_tracker)

    x << c

    assert_equal c, x[:Thing]
  end

  def test_top
    a = Brakeman::ClassName.new(:"::Top")
    b = Brakeman::ClassName.new(:"A::Top")

    refute_equal a, b
  end

  def test_unknown
    tracker = BrakemanTester.new_tracker

    assert tracker.models.include? Brakeman::Tracker::UNKNOWN_MODEL
  end
end
