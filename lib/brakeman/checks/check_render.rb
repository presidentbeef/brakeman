require 'brakeman/checks/base_check'

#Check calls to +render()+ for dangerous values
class Brakeman::CheckRender < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Finds calls to render that might allow file access"

  def run_check
    tracker.find_call(:target => nil, :method => :render).each do |result|
      process_render_result result
    end
  end

  def process_render_result result
    return unless node_type? result[:call], :render

    case result[:call].render_type
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

    if sexp? view and not duplicate? result
      add_result result


      if input = has_immediate_user_input?(view)
        confidence = CONFIDENCE[:high]
      elsif input = include_user_input?(view)
        if node_type? view, :string_interp, :dstr
          confidence = CONFIDENCE[:med]
        else
          confidence = CONFIDENCE[:low]
        end
      else
        return
      end

      return if input.type == :model #skip models

      message = "Render path contains #{friendly_type_of input}"

      warn :result => result,
        :warning_type => "Dynamic Render Path",
        :warning_code => :dynamic_render_path,
        :message => message,
        :user_input => input.match,
        :confidence => confidence
    end
  end
end 
