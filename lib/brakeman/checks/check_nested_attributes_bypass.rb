require 'brakeman/checks/base_check'

#https://groups.google.com/d/msg/rubyonrails-security/cawsWcQ6c8g/tegZtYdbFQAJ
class Brakeman::CheckNestedAttributesBypass < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for nested attributes vulnerability (CVE-2015-7577)"

  def run_check
    if version_between? "3.1.0", "3.2.22" or
       version_between? "4.0.0", "4.1.14" or
       version_between? "4.2.0", "4.2.5"

      unless workaround?
        check_nested_attributes
      end
    end
  end

  def check_nested_attributes
    active_record_models.each do |name, model|
      if opts = model.options[:accepts_nested_attributes_for]
        opts.each do |args|
          if args.any? { |a| allow_destroy? a } and args.any? { |a| reject_if? a }
            warn_about_nested_attributes name, model, args
          end
        end
      end
    end
  end

  def warn_about_nested_attributes name, model, args
    message = "Rails #{rails_version} does not call :reject_if option when :allow_destroy is false (CVE-2015-7577)"

    warn :model => name,
      :warning_type => "Nested Attributes",
      :warning_code => :CVE_2015_7577,
      :message => message,
      :file => model.file,
      :line => args.line,
      :confidence => :medium,
      :link_path => "https://groups.google.com/d/msg/rubyonrails-security/cawsWcQ6c8g/tegZtYdbFQAJ"
  end

  def allow_destroy? arg
    hash? arg and
      false? hash_access(arg, :allow_destroy)
  end

  def reject_if? arg
    hash? arg and
      hash_access(arg, :reject_if)
  end

  def workaround?
    tracker.check_initializers([], :will_be_destroyed?).any?
  end
end
