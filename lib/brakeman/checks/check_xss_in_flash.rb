require 'brakeman/checks/cross_site_scripting_base_check'

class Brakeman::CheckXssInFlash < Brakeman::CrossSiteScriptingBaseCheck
  Brakeman::Checks.add self

  @description = "Check XSS attacks via the flash object"

  def initialize *args
    super
    @warning_type = "XSS in flash"
  end

  def run_check
    setup

    # what should we store? Do we need to store all results or just one?
    @unsafe_flash_assignments = []
    @unsafe_flash_renderings = []

    tracker.find_call(:method => :[]=, :target => :flash).each do |result|
      process_result_for_assignments result
    end

    tracker.each_template do |_name, template|
      process_result_for_renderings template
    end

    # Give high confidence warnings on both assignment and rendering when both present
    # Give warning with lower confidence when there is only risky rendering
    # If assign but always escape, no warnings
    if @unsafe_flash_assignments.any? && @unsafe_flash_renderings.any?
      @unsafe_flash_assignments.each do |warning_args|
        warn warning_args.merge(confidence: :high)
      end

      @unsafe_flash_renderings.each do |warning_args|
        warn warning_args.merge(confidence: :high)
      end
    elsif @unsafe_flash_renderings.any?
      @unsafe_flash_renderings.each do |warning_args|
        warn warning_args.merge(confidence: :low)
      end
    end
  end

  def warn_for_immediate_xss(_exp, out)
    if call?(out) && out.method == :flash
      @unsafe_flash_renderings << {
        :template => @current_template,
        :warning_type => @warning_type,
        :warning_code => :rendering_unescaped_flash_value,
        :message => "Unsafe output using flash object",
        :code => out,
      }
    end
  end

  def process_call exp
    if @mark
      actually_process_call exp
    else
      @mark = true
      actually_process_call exp

      if @matched and not duplicate? exp
        add_result exp

        @unsafe_flash_renderings << {
          :template => @current_template,
          :warning_type => @warning_type,
          :warning_code => :rendering_unescaped_flash_value,
          :message => "Unsafe output using flash object",
          :code => exp,
        }
      end

      @mark = @matched = false
    end

    exp
  end

  def set_matched!(exp, _target)
    if exp.method == :flash
      @matched = Match.new(:flash, exp)
    end
  end

  def is_flash? exp
    if call?(exp) && exp.method == :flash
      return true
    end

    exp.each_sexp do |sexp|
      return true if is_flash? sexp
    end

    false
  end

  def process_result_for_assignments result
    return unless original? result

    message = result[:call].second_arg

    if input = has_immediate_user_input?(message)
      @unsafe_flash_assignments << {
        :result => result,
        :warning_type => @warning_type,
        :warning_code => :assigning_user_input_in_flash,
        :message => msg(msg_input(input), " is being used in the flash object"),
        :user_input => input,
      }
    end
  end

  def process_result_for_renderings template
    @current_template = template

    template.each_output do |out|
      if template.name == "groups/xss_in_flash"
        @xss_in_flash = true
      end

      if is_flash? out
        unless check_for_immediate_xss out
          @matched = false
          @mark = false
          process out
        end
      end

      break
    end
  end
end
