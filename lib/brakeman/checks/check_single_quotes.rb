require 'brakeman/checks/base_check'

#Checks for versions which do not escape single quotes.
#https://groups.google.com/d/topic/rubyonrails-security/kKGNeMrnmiY/discussion
class Brakeman::CheckSingleQuotes < Brakeman::BaseCheck
  Brakeman::Checks.add self
  RACK_UTILS = Sexp.new(:colon2, Sexp.new(:const, :Rack), :Utils)

  @description = "Check for versions which do not escape single quotes (CVE-2012-3464)"

  def initialize *args
    super
    @inside_erb = @inside_util = @inside_html_escape = @uses_rack_escape = false
  end

  def run_check
    return if uses_rack_escape?

    case
    when version_between?('2.0.0', '2.3.14')
      message = "All Rails 2.x versions do not escape single quotes (CVE-2012-3464)"
    when version_between?('3.0.0', '3.0.16')
      message = "Rails #{tracker.config[:rails_version]} does not escape single quotes (CVE-2012-3464). Upgrade to 3.0.17"
    when version_between?('3.1.0', '3.1.7')
      message = "Rails #{tracker.config[:rails_version]} does not escape single quotes (CVE-2012-3464). Upgrade to 3.1.8"
    when version_between?('3.2.0', '3.2.7')
      message = "Rails #{tracker.config[:rails_version]} does not escape single quotes (CVE-2012-3464). Upgrade to 3.2.8"
    else
      return
    end

    warn :warning_type => "Cross Site Scripting",
      :message => message,
      :confidence => CONFIDENCE[:med],
      :file => gemfile_or_environment,
      :link_path => "https://groups.google.com/d/topic/rubyonrails-security/kKGNeMrnmiY/discussion"
  end

  #Process initializers to see if they use workaround
  #by replacing Erb::Util.html_escape
  def uses_rack_escape?
    @tracker.initializers.each do |name, src|
      process src
    end

    @uses_rack_escape
  end

  #Look for
  #
  #    class ERB
  def process_class exp
    if exp[1] == :ERB
      @inside_erb = true
      process exp[-1]
      @inside_erb = false
    end

    exp
  end

  #Look for
  #
  #    module Util
  def process_module exp
    if @inside_erb and exp[1] == :Util
      @inside_util = true
      process exp[-1]
      @inside_util = false
    end

    exp
  end

  #Look for
  #
  #    def html_escape
  def process_defn exp
    if @inside_util and exp[1] == :html_escape
      @inside_html_escape = true
      process exp[-1]
      @inside_html_escape = false
    end

    exp
  end

  #Look for
  #
  #    Rack::Utils.escape_html
  def process_call exp
    if @inside_html_escape and exp[1] == RACK_UTILS and exp[2] == :escape_html
      @uses_rack_escape = true
    else
      process exp[1] if exp[1]
    end

    exp
  end
end
