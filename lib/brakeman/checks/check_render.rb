require 'brakeman/checks/base_check'

#Check calls to +render()+ for dangerous values
class Brakeman::CheckRender < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Finds calls to render that might allow file access"

  def run_check
    tracker.find_call(:target => nil, :method => :render).each do |result|
      process_render result
    end
  end

  def process_render result
    case result[:call][1]
    when :partial, :template, :action, :file
      check_for_dynamic_path result
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

    if sexp? view and view.node_type != :str and view.node_type != :lit and not duplicate? result

      add_result result

      if include_user_input? view
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:low]
      end

      warning = { :warning_type => "Dynamic Render Path",
        :message => "Render path is dynamic",
        :line => result[:call].line,
        :code => result[:call],
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
end 
