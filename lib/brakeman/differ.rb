# extracting the diff logic to it's own class for consistency. Currently handles
# an array of Brakeman::Warnings or plain hash representations.  
class Brakeman::Differ
  DEFAULT_HASH = {:new => [], :fixed => []}
  OLD_WARNING_KEYS = [:warning_type, :location, :code, :message, :file, :link, :confidence, :user_input]
  attr_reader :old_warnings, :new_warnings

  def initialize new_warnings, old_warnings
    @new_warnings = new_warnings
    @old_warnings = old_warnings
  end

  def diff
    # get the type of elements
    return DEFAULT_HASH if @new_warnings.empty?

    warnings = {}
    warnings[:new] = @new_warnings - @old_warnings
    warnings[:fixed] = @old_warnings - @new_warnings

    second_pass(warnings)
  end

  # second pass to cleanup any vulns which have changed in line number only.
  # Given a list of new warnings, delete pairs of new/fixed vulns that differ
  # only by line number.
  # Horrible O(n^2) performance.  Keep n small :-/
  def second_pass(warnings)
    # keep track of the number of elements deleted because the index numbers
    # won't update as the list is modified
    elements_deleted_offset = 0

    # dup this list since we will be deleting from it and the iterator gets confused.
    # use _with_index for fast deletion as opposed to .reject!{|obj| obj == *_warning}
    warnings[:new].dup.each_with_index do |new_warning, new_warning_id|
      warnings[:fixed].each_with_index do |fixed_warning, fixed_warning_id|
        if eql_except_line_number new_warning, fixed_warning
          warnings[:new].delete_at(new_warning_id - elements_deleted_offset)
          elements_deleted_offset += 1
          warnings[:fixed].delete_at(fixed_warning_id)
          break
        end
      end
    end

    warnings
  end

  def eql_except_line_number new_warning, fixed_warning
    # can't do this ahead of time, as callers may be expecting a Brakeman::Warning
    if new_warning.is_a? Brakeman::Warning 
      new_warning = new_warning.to_hash
      fixed_warning = fixed_warning.to_hash
    end

    if new_warning[:fingerprint] and fixed_warning[:fingerprint]
      new_warning[:fingerprint] == fixed_warning[:fingerprint]
    else
     OLD_WARNING_KEYS.each do |attr|
        return false if new_warning[attr] != fixed_warning[attr]
      end

      true
    end
  end
end
