require 'brakeman/checks/base_check'

class Brakeman::CheckFileContentDisclosure < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = 'Checks for versions with file content disclosure vulnerability'

  def run_check
    fix_version = case
      when version_between?('0.0.0', '4.2.11')
        '4.2.11.1 '
      when version_between?('5.0.0.beta1', '5.0.7.2')
        '5.0.7.2'
      when version_between?('5.1.0.beta1', '5.1.6.1')
        '5.1.6.2'
      when version_between?('5.2.0.beta1', '5.2.2')
        '5.2.2.1'
      when version_between?('6.0.0.beta1', '6.0.0.beta2')
        '6.0.0.beta3'
      else
        nil
      end

    if fix_version and render_file_with_no_specific_format?
      warn :warning_type => "File Access",
        :warning_code => :CVE_2019_5418,
        :message => msg(msg_version(rails_version), " has a file content disclosure vulnerability. Upgrade to ", msg_version(fix_version), " or specify a file format"),
        :confidence => :high,
        :gem_info => gemfile_or_environment,
        :link_path => "https://groups.google.com/g/rubyonrails-security/c/pFRKI96Sm8Q"
    end
  end

  def render_file_with_no_specific_format?
    tracker.find_call(:target => nil, :method => :render).each do |result|
      process_render_result result
    end
  end

  # vulnerable controllers will use:
  # render file: "#{Rails.root}/some/file"
  def process_render_result result
    return unless node_type? result[:call], :render

    case result[:call].render_type
    when :file
      check_for_absence_of_formats_option(result)
    end
  end

  # vulnerability can be mitigated with a specific format:
  # render file: "#{Rails.root}/some/file", formats: [:html]
  def check_for_absence_of_formats_option result
    exp = result[:call].last

    if sexp? exp and exp.node_type == :hash
      exp.each_sexp do |e|
        Match.new(:formats, e)
      end
    end.empty?
  end
end
