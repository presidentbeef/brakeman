require_relative '../test'

class TrackerTests < Minitest::Test
  def setup
    @tracker = BrakemanTester.new_tracker
  end

  def test_exception_in_error_list
    @tracker.error Exception.new

    assert_equal 1, @tracker.errors.length

    @tracker.errors.each do |e|
      assert e.has_key? :exception
      assert e.has_key? :error
      assert e.has_key? :backtrace

      assert e[:exception].is_a? Exception
      assert e[:error].is_a? String
      assert e[:backtrace].is_a? Array
    end
  end

  def test_method_lookup_default_type
    parse_class
    assert @tracker.find_method(:boo, :Example)
  end

  def test_method_lookup_instance
    parse_class
    assert @tracker.find_method(:boo, :Example, :instance)
  end

  def test_method_lookup_class
    parse_class
    assert @tracker.find_method(:far, :Example, :class)
  end

  def test_method_lookup_wrong_type
    parse_class
    assert_nil @tracker.find_method(:far, :Example, :instance)
  end

  def test_method_lookup_no_method
    parse_class
    assert_nil @tracker.find_method(:farther, :Example, :class)
  end

  def test_method_lookup_in_parent
    parse_class
    assert @tracker.find_method(:zoop, :Example, :instance)
  end

  def test_method_lookup_in_mixin
    parse_class
    assert @tracker.find_method(:mixed, :Example)
  end

  def test_method_lookup_in_module
    parse_class
    assert @tracker.find_method(:mixed, :Mixin)
  end

  def test_method_lookup_invalid_type
    parse_class
    assert_raises do
      assert @tracker.find_method(:far, :Example, :invalid_type)
    end
  end

  def test_method_inside_sclass
    parse_class
    assert @tracker.find_method(:class_method, :Example, :class)
  end

  def test_class_method_in_parent
    parse_class
    assert @tracker.find_method(:parent_class_method, :Example, :class)
  end

  def test_invalid_method_info_src
    assert_raises do
      Brakeman::MethodInfo.new(:blah, s(:not_a_defn), nil, nil)
    end
  end

  def test_module_includes_in_same_class
    ast = RubyParser.new.parse <<~RUBY
      module Mixin
        def self.builds_self
          Class.new { include Mixin }
        end
      end
    RUBY

    Brakeman::LibraryProcessor.new(@tracker).process_library(ast, 'fake_file_name.rb')
    assert_nil @tracker.find_method(:builds_self, :Mixin)
  end

  private

  def parse_class
    ast = RubyParser.new.parse <<-RUBY
    module Mixin
      def mixed
      end
    end

    class Parent
      def zoop
      end

      def self.parent_class_method
      end
    end

    class Example < Parent
      include Mixin

      def boo
      end

      def self.far
      end

      class << self
        def class_method
        end
      end
    end
    RUBY

    Brakeman::LibraryProcessor.new(@tracker).process_library(ast, 'fake_file_name.rb')
  end
end
