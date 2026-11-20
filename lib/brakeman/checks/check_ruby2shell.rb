require 'brakeman/checks/base_check'

class Brakeman::CheckRuby2Shell < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = 'Check for versions of Ruby vulnerable to Ruby2Shell'

  def run_check
    ruby_version = tracker.config.ruby_version
    return unless ruby_version

    fix_version = case
                  when version_between?('2.4.0', '3.3.13', ruby_version)
                    '3.3.14'
                  when version_between?('3.4.0', '3.4.12', ruby_version)
                    '3.4.13'
                  when version_between?('4.0.0', '4.0.9', ruby_version)
                    '4.0.10'
                  end

    if fix_version
      warn warning_type: 'Remote Code Execution',
        warning_code: :ruby2shell,
        message: msg(msg_version(ruby_version, 'Ruby'), ' has a critical remote code execution vulnerability ', msg_cve('CVE-2026-132825'), '. Upgrade to ', msg_version(fix_version, 'Ruby'), ' or later'),
        confidence: :high,
        gem_info: gemfile_or_environment('ruby'),
        link: 'https://www.ruby-lang.org/en/news/2026/11/18/multiple-vulnerabilities-in-regexp-and-string/',
        cwe_id: [122, 125, 787]
    end
  end
end
