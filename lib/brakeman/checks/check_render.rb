require 'brakeman/checks/base_check'

#Check calls to +render()+ for dangerous values
class Brakeman::CheckRender < Brakeman::BaseCheck
  Brakeman::Checks.add self

  def run_check
    tracker.each_method do |src, class_name, method_name|
      @current_class = class_name
      @current_method = method_name
      process src
    end

    tracker.each_template do |name, template|
      @current_template = template
      process template[:src]
    end
  end

  def process_render exp
    case exp[1]
    when :partial, :template, :action, :file
      check_for_dynamic_path exp
    when :inline
    when :js
    when :json
    when :text
    when :update
    when :xml
    end
    exp
  end

  #Check if path to action or file is determined dynamically
  def check_for_dynamic_path exp
    view = exp[2]

    if sexp? view and view.node_type != :str and view.node_type != :lit and not duplicate? exp

      add_result exp

      if include_user_input? view
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:low]
      end

      warning = { :warning_type => "Dynamic Render Path",
        :message => "Render path is dynamic",
        :line => exp.line,
        :code => exp,
        :confidence => confidence }


      if @current_template
        warning[:template] = @current_template
      else
        warning[:class] = @current_class
        warning[:method] = @current_method
      end

      warn warning
    end
  end
end 
