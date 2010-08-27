require 'checks/base_check'
require 'processors/lib/find_call'
require 'processors/lib/processor_helper'
require 'util'
require 'set'

#This check looks for unescaped output in templates which contains
#parameters or model attributes.
#
#For example:
#
# <%= User.find(:id).name %>
# <%= params[:id] %>
class CheckCrossSiteScripting < BaseCheck
  Checks.add self

  #Ignore these methods and their arguments.
  #It is assumed they will take care of escaping their output.
  IGNORE_METHODS = Set.new([:h, :escapeHTML, :link_to, :text_field_tag, :hidden_field_tag,
                           :image_tag, :select, :submit_tag, :hidden_field, :url_encode,
                           :radio_button, :will_paginate, :button_to, :url_for, :mail_to,
                           :fields_for, :label, :text_area, :text_field, :hidden_field, :check_box,
                           :field_field]) 

  IGNORE_MODEL_METHODS = Set.new([:average, :count, :maximum, :minimum, :sum])

  MODEL_METHODS = Set.new([:all, :find, :first, :last, :new])

  IGNORE_LIKE = /^link_to_|_path|_tag|_url$/

  HAML_HELPERS = Sexp.new(:colon2, Sexp.new(:const, :Haml), :Helpers)

  URI = Sexp.new(:const, :URI)

  CGI = Sexp.new(:const, :CGI)

  FORM_BUILDER = Sexp.new(:call, Sexp.new(:const, :FormBuilder), :new, Sexp.new(:arglist)) 

  #Run check
  def run_check 
    IGNORE_METHODS.merge OPTIONS[:safe_methods]
    @models = tracker.models.keys
    @inspect_arguments = OPTIONS[:check_arguments]

    tracker.each_template do |name, template|
      @current_template = template

      template[:outputs].each do |out|
        type, match = has_immediate_user_input?(out[1])
        if type
          unless duplicate? out
            add_result out
            case type
            when :params

              warn :template => @current_template, 
                :warning_type => "Cross Site Scripting", 
                :message => "Unescaped parameter value",
                :line => match.line,
                :code => match,
                :confidence => CONFIDENCE[:high]

            when :cookies

              warn :template => @current_template, 
                :warning_type => "Cross Site Scripting", 
                :message => "Unescaped cookie value",
                :line => match.line,
                :code => match,
                :confidence => CONFIDENCE[:high]
            end
          end
        elsif not OPTIONS[:ignore_model_output] and match = has_immediate_model?(out[1])
          method = match[2]

          unless duplicate? out or IGNORE_MODEL_METHODS.include? method
            add_result out

            if MODEL_METHODS.include? method or method.to_s =~ /^find_by/
              confidence = CONFIDENCE[:high]
            else
              confidence = CONFIDENCE[:med]
            end

            code = find_chain out, match
            warn :template => @current_template,
              :warning_type => "Cross Site Scripting", 
              :message => "Unescaped model attribute",
              :line => code.line,
              :code => code,
              :confidence => confidence
          end

        else
          @matched = false
          @mark = false
          process out
        end
      end
    end
  end

  #Process an output Sexp
  def process_output exp
    process exp[1]
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

      if @matched == :model and not OPTIONS[:ignore_model_output]
        message = "Unescaped model attribute" 
      elsif @matched == :params
        message = "Unescaped parameter value" 
      end

      if message and not duplicate? exp
        add_result exp

        warn :template => @current_template, 
          :warning_type => "Cross Site Scripting", 
          :message => message,
          :line => exp.line,
          :code => exp,
          :confidence => CONFIDENCE[:low]
      end

      @mark = @matched = false
    end

    exp
  end

  def actually_process_call exp
    return if @matched
    target = exp[1]
    if sexp? target
      target = process target
    end

    method = exp[2]
    args = exp[3]

    #Ignore safe items
    if (target.nil? and (IGNORE_METHODS.include? method or method.to_s =~ IGNORE_LIKE)) or
      (@matched == :model and IGNORE_MODEL_METHODS.include? method) or
      (target == HAML_HELPERS and method == :html_escape) or
      ((target == URI or target == CGI) and method == :escape) or
      (target == FORM_BUILDER and IGNORE_METHODS.include? method) or
      (method.to_s[-1,1] == "?")

      exp[0] = :ignore
      @matched = false
    elsif sexp? exp[1] and model_name? exp[1][1]

      @matched = :model
    elsif @inspect_arguments and (ALL_PARAMETERS.include?(exp) or params? exp)

      @matched = :params
    else
      process args if @inspect_arguments
    end
  end

  #Note that params have been found
  def process_params exp
    @matched = :params
    exp
  end

  #Note that cookies have been found
  def process_cookies exp
    @matched = :cookies
    exp
  end

  #Ignore calls to render
  def process_render exp
    exp
  end

  #Process as default
  def process_string_interp exp
    process_default exp
  end

  #Process as default
  def process_format exp
    process_default exp
  end

  #Ignore output HTML escaped via HAML
  def process_format_escaped exp
    exp
  end

  #Ignore condition in if Sexp
  def process_if exp
    exp[2..-1].each do |e|
      process e if sexp? e
    end
    exp
  end

end
