require 'brakeman/checks/base_check'

# Checks for unscoped calls to models' #find and #find_by_id methods.
class Brakeman::CheckUnscopedFind < Brakeman::BaseCheck
  Brakeman::Checks.add_optional self

  @description = "Check for unscoped ActiveRecord queries"

  def run_check
    Brakeman.debug("Finding instances of #find on models with associations")

    associated_model_names = active_record_models.keys.select do |name|
      active_record_models[name].associations[:belongs_to]
    end

    calls = tracker.find_call :method => [:find, :find_by_id, :find_by_id!],
                              :targets => associated_model_names

    calls.each do |call|
      process_result call
    end
  end

  def process_result result
    return if duplicate? result or result[:call].original_line

    # Not interested unless argument is user controlled.
    inputs = result[:call].args.map { |arg| include_user_input?(arg) }
    return unless input = inputs.compact.first

    add_result result

    warn :result => result,
      :warning_type => "Unscoped Find",
      :warning_code => :unscoped_find,
      :message      => "Unscoped call to #{result[:target]}##{result[:method]}",
      :code         => result[:call],
      :confidence   => :weak,
      :user_input   => input
  end
end
