# extracting the diff logic to it's own class for consistency currently handles
# an array of Brakeman::Warnings or plain hash representations.  
class Brakeman::Differ
  DEFAULT_HASH = {:new => [], :fixed => []}
  attr_reader :old_warnings, :new_warnings

  def initialize new_warnings, old_warnings
    @new_warnings = new_warnings
    @old_warnings = old_warnings
  end

  def diff
    # get the type of elements
    return DEFAULT_HASH if @old_warnings.empty? && @new_warnings.empty?

    warnings = {}
    warnings[:new] = @new_warnings - @old_warnings
    warnings[:fixed] = @old_warnings - @new_warnings

    second_pass(warnings)
  end

  # second pass to cleanup any vulns which have changed in line number only
  # Horrible O(n^2) performance.  Keep n small :-/
  def second_pass(warnings)
    warnings[:new].each_with_index do |new_warning, new_warning_id|
      warnings[:fixed].each_with_index do |fixed_warning, fixed_warning_id|
        if matches_except_line new_warning, fixed_warning
          warnings[:new].delete_at new_warning_id
          warnings[:fixed].delete_at fixed_warning_id
        end
      end
    end

    warnings
  end

  def matches_except_line new_warning, fixed_warning
    # can't do this ahead of time, as callers may be expecting a Brakeman::Warning
    if new_warning.is_a? Brakeman::Warning 
      new_warning = new_warning.to_hash
      fixed_warning = fixed_warning.to_hash
    end

    new_warning.keys.reject{|k,v| k == :line}.each do |attr|
      if new_warning[attr] != fixed_warning[attr]
        return false 
      end
    end
    true
  end
end
