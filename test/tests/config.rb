require_relative '../test'

class RailsConfiguration < Minitest::Test
  def test_rails5_2_configuration_load_defaults
    tracker = Brakeman.run(File.join(TEST_PATH, "apps", "rails5.2"))

    refute tracker.config.rails.empty?

    assert_equal tracker.config.rails[:load_defaults], Sexp.new(:lit, 5.2)
  end
end
