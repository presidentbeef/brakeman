require 'brakeman/checks/base_check'

#Check calls to +render()+ for dangerous values
class Brakeman::CheckRender < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Finds calls to render that might allow file access or code execution"

  def run_check
    tracker.find_call(:target => nil, :method => :render).each do |result|
      process_render_result result
    end
  end

  def process_render_result result
    return unless node_type? result[:call], :render

    case result[:call].render_type
    when :partial, :template, :action, :file
      check_for_rce(result) or
        check_for_dynamic_path(result)
    when :inline
    when :js
    when :json
    when :text
    when :update
    when :xml
    end
  end

  #Check if path to action or file is determined dynamically
  def check_for_dynamic_path result
    view = result[:call][2]

    if sexp? view and not duplicate? result
      add_result result

      if input = has_immediate_user_input?(view)
        if string_interp? view
          confidence = CONFIDENCE[:med]
        else
          confidence = CONFIDENCE[:high]
        end
      elsif input = include_user_input?(view)
        confidence = CONFIDENCE[:low]
      else
        return
      end

      return if input.type == :model #skip models
      return if safe_param? input.match

      message = "Render path contains #{friendly_type_of input}"

      warn :result => result,
        :warning_type => "Dynamic Render Path",
        :warning_code => :dynamic_render_path,
        :message => message,
        :user_input => input,
        :confidence => confidence
    end
  end

  def check_for_rce result
    return unless version_between? "0.0.0", "3.2.22" or
                  version_between? "4.0.0", "4.1.14" or
                  version_between? "4.2.0", "4.2.5"


    view = result[:call][2]
    if sexp? view and not duplicate? result
      if params? view
        add_result result
        return if safe_param? view

        warn :result => result,
          :warning_type => "Remote Code Execution",
          :warning_code => :dynamic_render_path_rce,
          :message => "Passing query parameters to render() is vulnerable in Rails #{rails_version} (CVE-2016-0752)",
          :user_input => view,
          :confidence => CONFIDENCE[:high]
      end
    end
  end

  def safe_param? exp
    if params? exp and call? exp
      method_name = exp.method

      if method_name == :[]
        arg = exp.first_arg
        symbol? arg and [:controller, :action].include? arg.value
      else
        boolean_method? method_name
      end
    end
  end
end 
