require 'brakeman/checks/base_check'
require 'brakeman/processors/lib/find_call'

#Checks for string interpolation and parameters in calls to
#Kernel#system, Kernel#exec, Kernel#syscall, and inside backticks.
#
#Examples of command injection vulnerabilities:
#
# system("rf -rf #{params[:file]}")
# exec(params[:command])
# `unlink #{params[:something}`
class Brakeman::CheckExecute < Brakeman::BaseCheck
  Brakeman::Checks.add self

  #Check models, controllers, and views for command injection.
  def run_check
    check_for_backticks tracker

    calls = tracker.find_call [:IO, :Open3, :Kernel, []], [:exec, :popen, :popen3, :syscall, :system]

    calls.each do |result|
      process result
    end
  end

  #Processes results from FindCall.
  def process_result exp
    call = exp[-1]

    args = process call[3]

    case call[2]
    when :system, :exec
      failure = include_user_input?(args[1]) || include_interp?(args[1])
    else
      failure = include_user_input?(args) || include_interp?(args)
    end

    if failure and not duplicate? call, exp[1]
      add_result call, exp[1]

      if @string_interp
        confidence = CONFIDENCE[:med]
      else
        confidence = CONFIDENCE[:high]
      end

      warn :result => exp,
        :warning_type => "Command Injection", 
        :message => "Possible command injection",
        :line => call.line,
        :code => call,
        :confidence => confidence
    end

    exp
  end

  #Looks for calls using backticks such as
  #
  # `rm -rf #{params[:file]}`
  def check_for_backticks tracker
    tracker.each_method do |exp, set_name, method_name|
      @current_set = set_name
      @current_method = method_name

      process exp
    end 

    @current_set = nil

    tracker.each_template do |name, template|
      @current_template = template

      process template[:src]
    end

    @current_template = nil
  end

  #Processes backticks.
  def process_dxstr exp
    return exp if duplicate? exp 

    add_result exp

    if include_user_input? exp
      confidence = CONFIDENCE[:high]
    else
      confidence = CONFIDENCE[:med]
    end

    warning = { :warning_type => "Command Injection",
      :message => "Possible command injection",
      :line => exp.line,
      :code => exp,
      :confidence => confidence }

    if @current_template
      warning[:template] = @current_template
    else
      warning[:class] = @current_set
      warning[:method] = @current_method
    end

    warn warning

    exp
  end
end
