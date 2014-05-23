require 'brakeman/checks/base_check'

class Brakeman::CheckModelSerialize < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Report uses of serialize in versions vulnerable to CVE-2013-0277"

  def run_check
    @upgrade_version = case
                      when version_between?("2.0.0", "2.3.16")
                        "2.3.17"
                      when version_between?("3.0.0", "3.0.99")
                        "3.2.11"
                      else
                        nil
                      end

    return unless @upgrade_version

    tracker.models.each do |name, model|
      check_for_serialize model
    end
  end

  #High confidence warning on serialized, unprotected attributes.
  #Medium confidence warning for serialized, protected attributes.
  def check_for_serialize model
    if serialized_attrs = model[:options] && model[:options][:serialize]
      attrs = Set.new

      serialized_attrs.each do |arglist|
        arglist.each do |arg|
          attrs << arg if symbol? arg
        end
      end

      if unsafe_attrs = model[:attr_accessible]
        attrs.delete_if { |attr| not unsafe_attrs.include? attr.value }
      elsif protected_attrs = model[:options][:attr_protected]
        safe_attrs = Set.new

        protected_attrs.each do |arglist|
          arglist.each do |arg|
            safe_attrs << arg if symbol? arg
          end
        end

        attrs.delete_if { |attr| safe_attrs.include? attr }
      end

      if attrs.empty?
        confidence = CONFIDENCE[:med]
      else
        confidence = CONFIDENCE[:high]
      end

      warn :model => model[:name],
        :warning_type => "Remote Code Execution",
        :warning_code => :CVE_2013_0277,
        :message => "Serialized attributes are vulnerable in Rails #{tracker.config[:rails_version]}, upgrade to #{@upgrade_version} or patch.",
        :confidence => confidence,
        :link => "https://groups.google.com/d/topic/rubyonrails-security/KtmwSbEpzrU/discussion",
        :file => model[:files].first
    end
  end
end
