require 'brakeman/checks/base_check'

#Check for bypassing mass assignment protection
#with without_protection => true
#
#Only for Rails 3.1
class Brakeman::CheckWithoutProtection < Brakeman::BaseCheck
  Brakeman::Checks.add self

  def run_check
    if version_between? "0.0.0", "3.0.99"
      return
    end

    models = []
    tracker.models.each do |name, m|
      if parent?(tracker, m, :"ActiveRecord::Base")
        models << name
      end
    end

    return if models.empty?

    @results = Set.new

    debug_info "Finding all mass assignments"
    calls = tracker.find_call models, [:new,
      :attributes=, 
      :update_attribute, 
      :update_attributes, 
      :update_attributes!,
      :create,
      :create!]

    debug_info "Processing all mass assignments"
    calls.each do |result|
      process result
    end
  end

  #All results should be Model.new(...) or Model.attributes=() calls
  def process_result res
    call = res[-1]
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

    res
  end
end
