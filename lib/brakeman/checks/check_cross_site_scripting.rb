require 'brakeman/checks/cross_site_scripting_base_check'

#This check looks for unescaped output in templates which contains
#parameters or model attributes.
#
#For example:
#
# <%= User.find(:id).name %>
# <%= params[:id] %>
class Brakeman::CheckCrossSiteScripting < Brakeman::CrossSiteScriptingBaseCheck
  Brakeman::Checks.add self

  @description = "Checks for unescaped output in views"

  def initialize *args
    super
    @warning_type = "Cross-Site Scripting"
    @default_warning_code = :cross_site_scripting
  end

  #Run check
  def run_check
    setup

    tracker.each_template do |name, template|
      Brakeman.debug "Checking #{name} for XSS"

      @current_template = template

      template.each_output do |out|
        unless check_for_immediate_xss out
          @matched = false
          @mark = false
          process out
        end
      end
    end
  end

  def warn_for_immediate_xss(exp, out)
    warning_code = @default_warning_code

    if input = has_immediate_user_input?(out)
      add_result exp

      message = msg("Unescaped ", msg_input(input))
      warn :template => @current_template,
        :warning_type => @warning_type,
        :warning_code => warning_code,
        :message => message,
        :code => input.match,
        :confidence => :high

    elsif not tracker.options[:ignore_model_output] and match = has_immediate_model?(out)
      method = if call? match
                 match.method
               else
                 nil
               end

      unless IGNORE_MODEL_METHODS.include? method
        add_result exp

        if likely_model_attribute? match
          confidence = :high
        else
          confidence = :medium
        end

        message = "Unescaped model attribute"
        link_path = "cross_site_scripting"

        if node_type?(out, :call, :safe_call, :attrasgn, :safe_attrasgn) && out.method == :to_json
          message += " in JSON hash"
          link_path += "_to_json"
          warning_code = :xss_to_json
        end

        warn :template => @current_template,
          :warning_type => @warning_type,
          :warning_code => warning_code,
          :message => message,
          :code => match,
          :confidence => confidence,
          :link_path => link_path
      end

    else
      false
    end
  end


  #Check a call for user input
  #
  #
  #Since we want to report an entire call and not just part of one, use @mark
  #to mark when a call is started. Any dangerous values inside will then
  #report the entire call chain.
  def process_call exp
    if @mark
      actually_process_call exp
    else
      @mark = true
      actually_process_call exp
      message = nil

      if @matched
        unless @matched.type and tracker.options[:ignore_model_output]
          message = msg("Unescaped ", msg_input(@matched))
        end

        if message and not duplicate? exp
          add_result exp

          link_path = "cross_site_scripting"
          warning_code = :cross_site_scripting

          if @known_dangerous.include? exp.method
            confidence = :high
            if exp.method == :to_json
              message << msg_plain(" in JSON hash")
              link_path += "_to_json"
              warning_code = :xss_to_json
            end
          else
            confidence = :weak
          end

          warn :template => @current_template,
            :warning_type => @warning_type,
            :warning_code => warning_code,
            :message => message,
            :code => exp,
            :user_input => @matched,
            :confidence => confidence,
            :link_path => link_path
        end
      end

      @mark = @matched = false
    end

    exp
  end

  def set_matched!(exp, target)
    if sexp? target and model_name? target[1] #TODO: use method call?
      @matched = Match.new(:model, exp)
    elsif cookies? exp
      @matched = Match.new(:cookies, exp)
    elsif @inspect_arguments and params? exp
      @matched = Match.new(:params, exp)
    end
  end

end
