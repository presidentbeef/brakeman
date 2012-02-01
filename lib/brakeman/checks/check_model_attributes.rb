require 'brakeman/checks/base_check'

#Check if mass assignment is used with models
#which inherit from ActiveRecord::Base.
#
#If tracker.options[:collapse_mass_assignment] is +true+ (default), all models 
#which do not use attr_accessible will be reported in a single warning
class Brakeman::CheckModelAttributes < Brakeman::BaseCheck
  Brakeman::Checks.add self

  def run_check
    return if mass_assign_disabled?

    names = []

    tracker.models.each do |name, model|
      if model[:attr_accessible].nil? and parent? model, :"ActiveRecord::Base"
        if tracker.options[:collapse_mass_assignment]
          names << name.to_s
        else
          warn :model => name, 
            :warning_type => "Attribute Restriction",
            :message => "Mass assignment is not restricted using attr_accessible", 
            :confidence => CONFIDENCE[:high]
        end
      end
    end

    if tracker.options[:collapse_mass_assignment] and not names.empty?
      warn :model => names.sort.join(", "), 
        :warning_type => "Attribute Restriction", 
        :message => "Mass assignment is not restricted using attr_accessible", 
        :confidence => CONFIDENCE[:high]
    end
  end
end
