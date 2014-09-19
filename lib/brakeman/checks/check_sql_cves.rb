require 'brakeman/checks/base_check'

class Brakeman::CheckSQLCVEs < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for several SQL CVEs"

  def run_check
    check_rails_versions_against_cve_issues
    check_cve_2014_0080
  end

  def check_rails_versions_against_cve_issues
    issues = [
      {
        :cve => "CVE-2012-2660",
        :versions => [%w[2.0.0 2.3.14 2.3.17], %w[3.0.0 3.0.12 3.0.13], %w[3.1.0 3.1.4 3.1.5], %w[3.2.0 3.2.3 3.2.4]],
        :url => "https://groups.google.com/d/topic/rubyonrails-security/8SA-M3as7A8/discussion"
      },
      {
        :cve => "CVE-2012-2661",
        :versions => [%w[3.0.0 3.0.12 3.0.13], %w[3.1.0 3.1.4 3.1.5], %w[3.2.0 3.2.3 3.2.5]],
        :url => "https://groups.google.com/d/topic/rubyonrails-security/dUaiOOGWL1k/discussion"
      },
      {
        :cve => "CVE-2012-2695",
        :versions => [%w[2.0.0 2.3.14 2.3.15], %w[3.0.0 3.0.13 3.0.14], %w[3.1.0 3.1.5 3.1.6], %w[3.2.0 3.2.5 3.2.6]],
        :url => "https://groups.google.com/d/topic/rubyonrails-security/l4L0TEVAz1k/discussion"
      },
      {
        :cve => "CVE-2012-5664",
        :versions => [%w[2.0.0 2.3.14 2.3.15], %w[3.0.0 3.0.17 3.0.18], %w[3.1.0 3.1.8 3.1.9], %w[3.2.0 3.2.9 3.2.18]],
        :url => "https://groups.google.com/d/topic/rubyonrails-security/DCNTNp_qjFM/discussion"
      },
      {
        :cve => "CVE-2013-0155",
        :versions => [%w[2.0.0 2.3.15 2.3.16], %w[3.0.0 3.0.18 3.0.19], %w[3.1.0 3.1.9 3.1.10], %w[3.2.0 3.2.10 3.2.11]],
        :url => "https://groups.google.com/d/topic/rubyonrails-security/c7jT-EeN9eI/discussion"
      },

    ]

    unless lts_version? '2.3.18.6'
     issues << {
        :cve => "CVE-2013-6417",
        :versions => [%w[2.0.0 3.2.15 3.2.16], %w[4.0.0 4.0.1 4.0.2]],
        :url => "https://groups.google.com/d/msg/ruby-security-ann/niK4drpSHT4/g8JW8ZsayRkJ"
      }
    end

    if tracker.config[:gems][:pg]
      issues << {
        :cve => "CVE-2014-3482",
        :versions => [%w[2.0.0 2.9.9 3.2.19], %w[3.0.0 3.2.18 3.2.19], %w[4.0.0 4.0.6 4.0.7], %w[4.1.0 4.1.2 4.1.3]],
        :url => "https://groups.google.com/d/msg/rubyonrails-security/wDxePLJGZdI/WP7EasCJTA4J"
      } <<
      {
        :cve => "CVE-2014-3483",
        :versions => [%w[2.0.0 2.9.9 3.2.19], %w[3.0.0 3.2.18 3.2.19], %w[4.0.0 4.0.6 4.0.7], %w[4.1.0 4.1.2 4.1.3]],
        :url => "https://groups.google.com/d/msg/rubyonrails-security/wDxePLJGZdI/WP7EasCJTA4J" }
    end

    issues.each do |cve_issue|
      cve_warning_for cve_issue[:versions], cve_issue[:cve], cve_issue[:url]
    end
  end

  def cve_warning_for versions, cve, link
    upgrade_version = upgrade_version? versions
    return unless upgrade_version

    code = cve.tr('-', '_').to_sym

    warn :warning_type => 'SQL Injection',
      :warning_code => code,
      :message => build_message(cve, upgrade_version),
      :confidence => CONFIDENCE[:high],
      :file => gemfile_or_environment,
      :link_path => link
  end

  def upgrade_version? versions
    versions.each do |low, high, upgrade|
      return upgrade if version_between? low, high
    end

    false
  end

  def check_cve_2014_0080
    return unless version_between? "4.0.0", "4.0.2" and
                  @tracker.config[:gems].include? :pg

    message = build_message 'CVE-2014-0080', '4.0.3'
    warn :warning_type => 'SQL Injection',
      :warning_code => :CVE_2014_0080,
      :message => build_message('CVE-2014-0080', '4.0.3'),
      :confidence => CONFIDENCE[:high],
      :file => gemfile_or_environment,
      :link_path => "https://groups.google.com/d/msg/rubyonrails-security/Wu96YkTUR6s/pPLBMZrlwvYJ"
  end

  def build_message cve, upgrade_version
    file = tracker.config[:gems][:rails][:file] if tracker.config[:gems][:rails]
    if file
      return "Rails #{tracker.config[:rails_version]} (#{file}) contains a SQL injection vulnerability (#{cve}). Upgrade to #{upgrade_version}"
    else
      return "Rails #{tracker.config[:rails_version]} contains a SQL injection vulnerability (#{cve}). Upgrade to #{upgrade_version}"
    end
  end
end
