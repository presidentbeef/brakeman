require 'brakeman/differ'

DiffRun = Brakeman.run :app_path => "#{TEST_PATH}/apps/rails2"

class DifferTests < Test::Unit::TestCase
  include BrakemanTester::DiffHelper

  def setup
    @warnings = DiffRun.warnings
  end

  def diff new, old
    @diff = Brakeman::Differ.new(new, old).diff
  end

  def assert_fixed expected, diff = @diff
    assert_equal expected, diff[:fixed].length, "Expected #{expected} fixed warnings, but found #{diff[:fixed].length}"
  end

  def assert_new expected, diff = @diff
    assert_equal expected, diff[:new].length, "Expected #{expected} new warnings, but found #{diff[:new].length}"
  end

  def test_sanity
    diff @warnings, @warnings

    assert_fixed 0
    assert_new 0
  end

  def test_one_fixed
    old = @warnings
    new = @warnings.dup
    new.shift

    diff new, old

    assert_fixed 1
    assert_new 0
  end

  def test_one_new
    new = @warnings
    old = @warnings.dup
    old.shift

    diff new, old

    assert_fixed 0
    assert_new 1
  end

  def test_new_and_fixed
    new = @warnings
    old = @warnings.dup

    new << old.pop
    old << new.shift

    diff new, old

    assert_new 2
    assert_fixed 2
  end

  def test_line_number_change_only
    new = @warnings
    old = @warnings.dup

    changed = new.pop.dup
    if changed.line.nil?
      changed.instance_variable_set(:@line, 0)
    else
      changed.instance_variable_set(:@line, changed.line + 1)
    end

    new << changed

    diff new, old

    assert_new 0
    assert_fixed 0
  end

  def test_new_vs_old_warning_keys_same_warnings
    new_keys = [:warning_code, :fingerprint, :render_path]

    new = @warnings
    old = @warnings.map do |warning|
      warning.to_hash.reject do |k, v|
        new_keys.include? k
      end
    end

    diff new, old
    assert_fixed 0
    assert_new 0
  end

  def test_new_vs_old_warning_keys_changed_warning
    new_keys = [:warning_code, :fingerprint, :render_path]

    new = @warnings
    old = @warnings.map do |warning|
      warning.to_hash.reject do |k, v|
        new_keys.include? k
      end
    end

    changed = new.pop.to_hash
    changed[:message] += "message has changed!"
    new << changed #check for new warning with different message

    diff new, old
    assert_fixed 1
    assert_new 1
  end
end
