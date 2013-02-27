require 'brakeman/checks/base_check'

#Check for uses of strip_tags in Rails versions before 3.0.17, 3.1.8, 3.2.8 (including 2.3.x):
#https://groups.google.com/d/topic/rubyonrails-security/FgVEtBajcTY/discussion
#
#Check for uses of strip_tags in Rails versions before 2.3.13 and 3.0.10:
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/2b9130749b74ea12
class Brakeman::CheckStripTags < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Report strip_tags vulnerabilities CVE-2011-2931 and CVE-2012-3465"

  def run_check
    if uses_strip_tags?
      cve_2011_2931
      cve_2012_3465
    end
  end

  def cve_2011_2931
    if version_between?('2.0.0', '2.3.12') or version_between?('3.0.0', '3.0.9')
      if tracker.config[:rails_version] =~ /^3/
        message = "Versions before 3.0.10 have a vulnerability in strip_tags (CVE-2011-2931)"
      else
        message = "Versions before 2.3.13 have a vulnerability in strip_tags (CVE-2011-2931)"
      end

      warn :warning_type => "Cross Site Scripting",
        :warning_code => :CVE_2011_2931,
        :message => message,
        :file => gemfile_or_environment,
        :confidence => CONFIDENCE[:high],
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/K5EwdJt06hI/discussion"
    end
  end

  def cve_2012_3465
    case
    when (version_between?('2.0.0', '2.3.14') and tracker.config[:escape_html])
      message = "All Rails 2.x versions have a vulnerability in strip_tags (CVE-2012-3465)"
    when version_between?('3.0.10', '3.0.16')
      message = "Rails #{tracker.config[:rails_version]} has a vulnerability in strip_tags (CVE-2012-3465). Upgrade to 3.0.17"
    when version_between?('3.1.0', '3.1.7')
      message = "Rails #{tracker.config[:rails_version]} has a vulnerability in strip_tags (CVE-2012-3465). Upgrade to 3.1.8"
    when version_between?('3.2.0', '3.2.7')
      message = "Rails #{tracker.config[:rails_version]} has a vulnerability in strip_tags (CVE-2012-3465). Upgrade to 3.2.8"
    else
      return
    end

    warn :warning_type => "Cross Site Scripting",
      :warning_code => :CVE_2012_3465,
      :message => message,
      :confidence => CONFIDENCE[:high],
      :file => gemfile_or_environment,
      :link_path => "https://groups.google.com/d/topic/rubyonrails-security/FgVEtBajcTY/discussion"
  end

  def uses_strip_tags?
    Brakeman.debug "Finding calls to strip_tags()"

    not tracker.find_call(:target => false, :method => :strip_tags).empty?
  end
end
