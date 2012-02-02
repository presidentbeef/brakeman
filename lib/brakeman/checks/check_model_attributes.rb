require 'brakeman/checks/base_check'

#Check if mass assignment is used with models
#which inherit from ActiveRecord::Base.
#
#If tracker.options[:collapse_mass_assignment] is +true+ (default), all models 
#which do not use attr_accessible will be reported in a single warning
class Brakeman::CheckModelAttributes < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Reports models which do not use attr_restricted and warns on models that use attr_protected"

  def run_check
    return if mass_assign_disabled?

    #Roll warnings into one warning for all models
    if tracker.options[:collapse_mass_assignment]
      no_accessible_names = []
      protected_names = []

      check_models do |name, model|
        if model[:options][:attr_protected].nil?
          no_accessible_names << name.to_s
        elsif not tracker.options[:ignore_attr_protected]
          protected_names << name.to_s
        end
      end

      unless no_accessible_names.empty?
        warn :model => no_accessible_names.sort.join(", "),
          :warning_type => "Attribute Restriction",
          :message => "Mass assignment is not restricted using attr_accessible",
          :confidence => CONFIDENCE[:high]
      end

      unless protected_names.empty?
        warn :model => protected_names.sort.join(", "),
          :warning_type => "Attribute Restriction",
          :message => "attr_accessible is recommended over attr_protected",
          :confidence => CONFIDENCE[:low]
      end
    else #Output one warning per model

      check_models do |name, model|
        if model[:options][:attr_protected].nil?
          warn :model => name,
            :file => model[:file],
            :warning_type => "Attribute Restriction",
            :message => "Mass assignment is not restricted using attr_accessible",
            :confidence => CONFIDENCE[:high]
        elsif not tracker.options[:ignore_attr_protected]
          warn :model => name,
            :file => model[:file],
            :line => model[:options][:attr_protected].first.line,
            :warning_type => "Attribute Restriction",
            :message => "attr_accessible is recommended over attr_protected",
            :confidence => CONFIDENCE[:low]
        end
      end
    end
  end

  def check_models
    tracker.models.each do |name, model|
      if model[:attr_accessible].nil? and parent? model, :"ActiveRecord::Base"
        yield name, model
      end
    end
  end
end
