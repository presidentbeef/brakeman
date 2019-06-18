require_relative '../test'
require 'brakeman/warning'

class WarningTests < Minitest::Test
  def test_confidence_symbols
    [:high, :med, :medium, :low, :weak].each do |c|
      w = Brakeman::Warning.new(confidence: c) 
      assert_equal Brakeman::Warning::CONFIDENCE[c], w.confidence
    end
  end

  def test_confidence_integers
    [0, 1, 2].each do |c|
      w = Brakeman::Warning.new(confidence: c) 
      assert_equal c, w.confidence
    end
  end

  def test_bad_confidence_symbol
    assert_raises do
      Brakeman::Warning.new(confidence: :blah)
    end
  end

  def test_bad_confidence_integer
    assert_raises do
      Brakeman::Warning.new(confidence: 10)
    end
  end

  def test_relative_path
    tracker = BrakemanTester.new_tracker
    path = tracker.app_tree.file_path("app/controllers/some_controller.rb")

    w = Brakeman::Warning.new(file: path, confidence: :high)

    refute w.relative_path.start_with? "/"
  end
end
