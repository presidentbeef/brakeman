require_relative '../test'
require 'brakeman/rescanner'

class MassAssignDisableTest < Minitest::Test
  include BrakemanTester::RescanTestHelper

  def mass_assign_disable content
    init = "config/initializers/mass_assign.rb"

    before_rescan_of init, "rails2" do
      write_file init, content
    end

    assert_fixed 4
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

  def test_strong_parameters_in_initializer
    init = "config/initializers/mass_assign.rb"
    gemfile = "Gemfile"
    config = "config/environments/production.rb"

    before_rescan_of [init, gemfile, config], "rails3.2" do
      write_file init, <<-RUBY
        class ActiveRecord::Base
          include ActiveModel::ForbiddenAttributesProtection
        end
      RUBY

      append gemfile, "gem 'strong_parameters'"

      replace config, "config.active_record.whitelist_attributes = true",
        "config.active_record.whitelist_attributes = false"
    end

    #We disable whitelist, but add strong_parameters globally, so
    #there should be no change.
    assert_fixed 0
    assert_new 0
  end

  def test_protected_attributes_gem_without_whitelist_attributes
    before_rescan_of "gems.rb", "rails4_with_engines" do
      append "gems.rb", "gem 'protected_attributes'"
    end

    # I misunderstood this previously - the protected_attributes gem
    # does not require use of attr_accessible, just allows it.
    assert_fixed 0
    assert_new 0
  end

  def test_protected_attributes_gem_with_whitelist_attributes
    config = "config/environments/production.rb"

    before_rescan_of ["gems.rb", config], "rails4_with_engines" do
      append "gems.rb", "gem 'protected_attributes'"

      replace config, "config.active_record.whitelist_attributes = false",
        "config.active_record.whitelist_attributes = true"
    end

    assert_fixed 0
    assert_new 0
  end

  def test_strong_parameters_with_send
    init = "config/initializers/mass_assign.rb"
    gemfile = "Gemfile"
    config = "config/environments/production.rb"

    before_rescan_of [init, gemfile, config], "rails3.2" do
      write_file init, <<-RUBY
        ActiveRecord::Base.send(:include,  ActiveModel::ForbiddenAttributesProtection)
      RUBY

      append gemfile, "gem 'strong_parameters'"

      replace config, "config.active_record.whitelist_attributes = true",
        "config.active_record.whitelist_attributes = false"
    end

    #We disable whitelist, but add strong_parameters globally, so
    #there should be no change.
    assert_fixed 0
    assert_new 0
  end
end
