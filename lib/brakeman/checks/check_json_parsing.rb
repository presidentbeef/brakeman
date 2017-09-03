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

      message = "Rails #{rails_version} has a serious JSON parsing vulnerability: upgrade to #{new_version} or patch"
      if uses_yajl?
        gem_info = gemfile_or_environment(:yajl)
      else
        gem_info = gemfile_or_environment
      end

      warn :warning_type => "Remote Code Execution",
        :warning_code => :CVE_2013_0333,
        :message => message,
        :confidence => :high,
        :gem_info => gem_info,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/1h2DR63ViGo/discussion"
    end
  end

  #Check if `yajl` is included in Gemfile
  def uses_yajl?
    tracker.config.has_gem? :yajl
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
      gem_hash = tracker.config.get_gem name
      check_json_version name, gem_hash[:version] if gem_hash and gem_hash[:version]
    end
  end

  def check_json_version name, version
    return if version >= "1.7.7" or
              (version >= "1.6.8" and version < "1.7.0") or
              (version >= "1.5.5" and version < "1.6.0")

    warning_type = "Denial of Service"
    confidence = :medium
    message = "#{name} gem version #{version} has a symbol creation vulnerablity: upgrade to "

    if version >= "1.7.0"
      confidence = :high
      warning_type = "Remote Code Execution"
      message = "#{name} gem version #{version} has a remote code vulnerablity: upgrade to 1.7.7"
    elsif version >= "1.6.0"
      message << "1.6.8"
    elsif version >= "1.5.0"
      message << "1.5.5"
    else
      confidence = :weak
      message << "1.5.5"
    end

    if confidence == :medium and uses_json_parse?
      confidence = :high
    end

    warn :warning_type => warning_type,
      :warning_code => :CVE_2013_0269,
      :message => message,
      :confidence => confidence,
      :gem_info => gemfile_or_environment(name),
      :link => "https://groups.google.com/d/topic/rubyonrails-security/4_YvCpLzL58/discussion"
  end

  def uses_json_parse?
    return @uses_json_parse unless @uses_json_parse.nil?

    not tracker.find_call(:target => :JSON, :method => :parse).empty?
  end
end
