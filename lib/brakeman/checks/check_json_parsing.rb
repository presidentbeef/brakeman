require 'brakeman/checks/base_check'

class Brakeman::CheckJSONParsing < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for JSON parsing vulnerabilities (CVE-2013-0333)"

  def run_check
    return unless version_between? "0.0.0", "2.3.15" or
                  version_between? "3.0.0", "3.0.19"

    unless uses_yajl? or uses_gem_backend?
      new_version = if version_between? "0.0.0", "2.3.14"
                      "2.3.16"
                    elsif version_between? "3.0.0", "3.0.19"
                      "3.0.20"
                    end

      message = "Rails #{tracker.config[:rails_version]} has a serious JSON parsing vulnerability: upgrade to #{new_version} or patch"

      warn :warning_type => "Remote Code Execution",
        :message => message,
        :confidence => CONFIDENCE[:high],
        :file => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/1h2DR63ViGo/discussion"
    end
  end

  #Check if `yajl` is included in Gemfile
  def uses_yajl?
    tracker.config[:gems] and tracker.config[:gems][:yajl]
  end

  #Check for `ActiveSupport::JSON.backend = "JSONGem"`
  def uses_gem_backend?
    matches = tracker.check_initializers(:'ActiveSupport::JSON', :backend=)

    unless matches.empty?
      json_gem = s(:str, "JSONGem")

      matches.each do |result|
        if result.call.first_arg == json_gem
          return true
        end
      end
    end

    false
  end
end
