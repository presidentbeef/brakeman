require 'brakeman/checks/base_check'

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
    debug_info "Finding system calls using ``"
    check_for_backticks tracker

    debug_info "Finding other system calls"
    calls = tracker.find_call :targets => [:IO, :Open3, :Kernel, nil], :methods => [:exec, :popen, :popen3, :syscall, :system]

    debug_info "Processing system calls"
    calls.each do |result|
      process_result result
    end
  end

  #Processes results from Tracker#find_call.
  def process_result result
    call = result[:call]

    args = process call[3]

    case call[2]
    when :system, :exec
      failure = include_user_input?(args[1]) || include_interp?(args[1])
    else
      failure = include_user_input?(args) || include_interp?(args)
    end

    if failure and not duplicate? result
      add_result result

      if @string_interp
        confidence = CONFIDENCE[:med]
      else
        confidence = CONFIDENCE[:high]
      end

      warn :result => result,
        :warning_type => "Command Injection", 
        :message => "Possible command injection",
        :line => call.line,
        :code => call,
        :confidence => confidence
    end
  end

  #Looks for calls using backticks such as
  #
  # `rm -rf #{params[:file]}`
  def check_for_backticks tracker
    tracker.find_call(:target => nil, :method => :`).each do |result|
      process_backticks result
    end
  end

  #Processes backticks.
  def process_backticks result
    return if duplicate? result

    add_result result

    exp = result[:call]

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

    if result[:location][0] == :template
      warning[:template] = result[:location][1]
    else
      warning[:class] = result[:location][1]
      warning[:method] = result[:location][2]
    end

    warn warning
  end
end
