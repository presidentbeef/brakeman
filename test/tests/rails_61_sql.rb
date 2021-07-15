require_relative '../test'
require 'brakeman/rescanner'

class Rails61SQLTests < Minitest::Test
  include BrakemanTester::RescanTestHelper

  # Test that `pluck`/`order`/`reorder` no longer warn about SQL injection
  # in Rails 6.1
  def test_pluck_safe_in_rails_6_1
    before_rescan_of ['app/controllers/groups_controller.rb', 'Gemfile'], 'rails6' do
      replace "Gemfile", "gem 'rails', '~> 6.0.0.beta2'", "gem 'rails', '6.1.0'"
    end

    assert_equal '6.1.0', @rescanner.tracker.config.rails_version
    assert_fixed 3
  end
end
