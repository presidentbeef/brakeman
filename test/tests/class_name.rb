require_relative "../test"
require "brakeman/tracker/class_name"

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

    assert x.empty?

    x << c

    refute x.empty?

    assert_equal c, x[:Thing]
  end
end
