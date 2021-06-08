require 'brakeman/checks/base_check'

class Brakeman::CheckXssInFlash < Brakeman::CheckCrossSiteScripting
  Brakeman::Checks.add self

  @description = "Check XSS attacks via the flash object"

  def run_check
    setup

    # what should we store? Do we need to store all results or just one?
    @unsafe_flash_assignments = nil
    @unsafe_flash_renderings = nil

    tracker.find_call(:method => :[]=, :target => :flash).each do |result|
      process_result_for_assignments result
    end

    tracker.each_template do |_name, template|
      process_result_for_renderings template
    end

    # if @unsafe_flash_assignments && @unsafe_flash_renderings
    #   warn :result => @unsafe_flash_assignments[:result],
    #     :warning_type => "XSS in flash",
    #     :warning_code => :xss_in_flash,
    #     :message => msg(msg_input(@unsafe_flash_assignments[:input]), " is being used in the flash object"),
    #     :user_input => input,
    #     :confidence => :high
    # end
  end

  def check_for_immediate_xss exp
    return :duplicate if duplicate? exp

    if exp.node_type == :output
      out = exp.value
    end

    if raw_call? exp
      out = exp.value.first_arg
    elsif html_safe_call? exp
      out = exp.value.target
    end

    return if call? out and ignore_call? out.target, out.method

    if call?(out) && out.method == :flash
      warn :template => @current_template,
        :warning_type => "XSS in flash",
        :warning_code => :xss_in_flash,
        :message => "Unsafe output using flash object",
        :confidence => :high

      return true
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

        warn :template => @current_template,
          :warning_type => "XSS in flash",
          :warning_code => :xss_in_flash,
          :message => "Unsafe output using flash object",
          :confidence => :high

      end

      @mark = @matched = false
    end

    exp
  end

  def actually_process_call exp
    return if @matched
    target = exp.target
    if sexp? target
      target = process target
    end

    method = exp.method

    #Ignore safe items
    if ignore_call? target, method
      @matched = false
    elsif method == :flash
      @matched = Match.new(:flash, exp)
    elsif @inspect_arguments
      process_call_args exp
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
      @unsafe_flash_assignments = true

      warn :result => result,
        :warning_type => "XSS in flash",
        :warning_code => :xss_in_flash,
        :message => msg(msg_input(input), " is being used in the flash object"),
        :user_input => input,
        :confidence => :high
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
