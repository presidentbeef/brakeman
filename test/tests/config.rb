require_relative '../test'

class RailsConfiguration < Minitest::Test
  def test_rails5_configuration
    tracker = Brakeman.run(File.join(TEST_PATH, "apps", "rails5"))

    refute tracker.config.rails.empty?
  end
end
