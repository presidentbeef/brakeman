require 'brakeman/checks/base_check'

class Brakeman::CheckJSONParsing < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for JSON parsing vulnerabilities CVE-2013-0333 and CVE-2013-0269"

  def run_check
    check_cve_2013_0333
    check_cve_2013_0269
  end

  def check_cve_2013_0333
    return unless version_between? "0.0.0", "2.3.15" or version_between? "3.0.0", "3.0.19"

    unless uses_yajl? or uses_gem_backend?
      new_version = if version_between? "0.0.0", "2.3.14"
                      "2.3.16"
                    elsif version_between? "3.0.0", "3.0.19"
                      "3.0.20"
                    end

      message = "Rails #{tracker.config[:rails_version]} has a serious JSON parsing vulnerability: upgrade to #{new_version} or patch"

      warn :warning_type => "Remote Code Execution",
        :warning_code => :CVE_2013_0333,
        :message => message,
        :confidence => CONFIDENCE[:high],
        :file => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/1h2DR63ViGo/discussion"
    end
  end

  #Check if `yajl` is included in Gemfile
  def uses_yajl?
    tracker.config[:gems][:yajl]
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

  def check_cve_2013_0269
    [:json, :json_pure].each do |name|
      version = tracker.config[:gems] && tracker.config[:gems][name]
      check_json_version name, version if version
    end
  end

  def check_json_version name, version
    return if version >= "1.7.7" or
              (version >= "1.6.8" and version < "1.7.0") or
              (version >= "1.5.5" and version < "1.6.0")

    warning_type = "Denial of Service"
    confidence = CONFIDENCE[:med]
    message = "#{name} gem version #{version} has a symbol creation vulnerablity: upgrade to "

    if version >= "1.7.0"
      confidence = CONFIDENCE[:high]
      warning_type = "Remote Code Execution"
      message = "#{name} gem version #{version} has a remote code vulnerablity: upgrade to 1.7.7"
    elsif version >= "1.6.0"
      message << "1.6.8"
    elsif version >= "1.5.0"
      message << "1.5.5"
    else
      confidence = CONFIDENCE[:low]
      message << "1.5.5"
    end

    if confidence == CONFIDENCE[:med] and uses_json_parse?
      confidence = CONFIDENCE[:high]
    end

    warn :warning_type => warning_type,
      :warning_code => :CVE_2013_0269,
      :message => message,
      :confidence => confidence,
      :file => gemfile_or_environment,
      :link => "https://groups.google.com/d/topic/rubyonrails-security/4_YvCpLzL58/discussion"
  end

  def uses_json_parse?
    return @uses_json_parse unless @uses_json_parse.nil?

    not tracker.find_call(:target => :JSON, :method => :parse).empty?
  end
end
