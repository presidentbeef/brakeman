class MassAssignDisableTest < Test::Unit::TestCase
  include BrakemanTester::RescanTestHelper

  def mass_assign_disable content
    init = "config/initializers/mass_assign.rb"

    before_rescan_of init, "rails2" do
      write_file init, content
    end

    assert_changes
    assert_fixed 3
    assert_new 0
  end

  def test_disable_mass_assignment_by_send
    mass_assign_disable "ActiveRecord::Base.send(:attr_accessible, nil)"
  end

  def test_disable_mass_assignment_by_module
    mass_assign_disable <<-RUBY
      module ActiveRecord
        class Base
          attr_accessible
        end
      end
    RUBY
  end

  def test_disable_mass_assignment_by_module_and_nil
    mass_assign_disable <<-RUBY
      module ActiveRecord
        class Base
          attr_accessible nil
        end
      end
    RUBY
  end
end
