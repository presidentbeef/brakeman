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
end
