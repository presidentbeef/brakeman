require 'brakeman/checks/base_check'

#Check for bypassing mass assignment protection
#with without_protection => true
#
#Only for Rails 3.1
class Brakeman::CheckWithoutProtection < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for mass assignment using without_protection"

  def run_check
    if version_between? "0.0.0", "3.0.99"
      return
    end

    models = []
    tracker.models.each do |name, m|
      if parent? m, :"ActiveRecord::Base"
        models << name
      end
    end

    return if models.empty?

    @results = Set.new

    Brakeman.debug "Finding all mass assignments"
    calls = tracker.find_call :targets => models, :methods => [:new,
      :attributes=, 
      :update_attribute, 
      :update_attributes, 
      :update_attributes!,
      :create,
      :create!]

    Brakeman.debug "Processing all mass assignments"
    calls.each do |result|
      process_result result
    end
  end

  #All results should be Model.new(...) or Model.attributes=() calls
  def process_result res
    call = res[:call]
    last_arg = call[3][-1]

    if hash? last_arg and not @results.include? call

      hash_iterate(last_arg) do |k,v|
        if symbol? k and k[1] == :without_protection and v[0] == :true
          @results << call

          if include_user_input? call[3]
            confidence = CONFIDENCE[:high]
          else
            confidence = CONFIDENCE[:med]
          end

          warn :result => res, 
            :warning_type => "Mass Assignment", 
            :message => "Unprotected mass assignment",
            :line => call.line,
            :code => call, 
            :confidence => confidence

          break
        end
      end
    end
  end
end
