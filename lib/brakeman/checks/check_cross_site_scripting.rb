require 'brakeman/checks/base_check'
require 'brakeman/processors/lib/find_call'
require 'brakeman/processors/lib/processor_helper'
require 'brakeman/util'
require 'set'

#This check looks for unescaped output in templates which contains
#parameters or model attributes.
#
#For example:
#
# <%= User.find(:id).name %>
# <%= params[:id] %>
class Brakeman::CheckCrossSiteScripting < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for unescaped output in views"

  #Model methods which are known to be harmless
  IGNORE_MODEL_METHODS = Set[:average, :count, :maximum, :minimum, :sum, :id]

  MODEL_METHODS = Set[:all, :find, :first, :last, :new]

  IGNORE_LIKE = /^link_to_|(_path|_tag|_url)$/

  HAML_HELPERS = Sexp.new(:colon2, Sexp.new(:const, :Haml), :Helpers)

  XML_HELPER = Sexp.new(:colon2, Sexp.new(:const, :Erubis), :XmlHelper)

  URI = Sexp.new(:const, :URI)

  CGI = Sexp.new(:const, :CGI)

  FORM_BUILDER = Sexp.new(:call, Sexp.new(:const, :FormBuilder), :new, Sexp.new(:arglist)) 

  #Run check
  def run_check 
    @ignore_methods = Set[:button_to, :check_box, :content_tag, :escapeHTML, :escape_once,
                           :field_field, :fields_for, :h, :hidden_field,
                           :hidden_field, :hidden_field_tag, :image_tag, :label,
                           :link_to, :mail_to, :radio_button,
                           :submit_tag, :text_area, :text_field,
                           :text_field_tag, :url_encode, :url_for,
                           :will_paginate].merge tracker.options[:safe_methods]

    @models = tracker.models.keys
    @inspect_arguments = tracker.options[:check_arguments]

    @known_dangerous = Set[:truncate, :concat]

    if version_between? "2.0.0", "3.0.5"
      @known_dangerous << :auto_link
    elsif version_between? "3.0.6", "3.0.99"
      @ignore_methods << :auto_link
    end

    if version_between? "2.0.0", "2.3.14"
      @known_dangerous << :strip_tags
    end

    if tracker.options[:rails3]
      @ignore_methods << :select
    end

    tracker.each_template do |name, template|
      @current_template = template
      template[:outputs].each do |out|
        Brakeman.debug "Checking #{name} for direct XSS"

        unless check_for_immediate_xss out
          Brakeman.debug "Checking #{name} for indirect XSS"

          @matched = false
          @mark = false
          process out
        end
      end
    end
  end

  def check_for_immediate_xss exp
    return if duplicate? exp

    if exp[0] == :output
      out = exp[1]
    elsif exp[0] == :escaped_output and raw_call? exp
      out = exp[1][3][1]
    end

    if input = has_immediate_user_input?(out)
      add_result exp

      case input.type
      when :params
        message = "Unescaped parameter value"
      when :cookies
        message = "Unescaped cookie value"
      when :request
        message = "Unescaped request value"
      else
        message = "Unescaped user input value"
      end

      warn :template => @current_template, 
        :warning_type => "Cross Site Scripting",
        :message => message,
        :code => input.match,
        :confidence => CONFIDENCE[:high]

    elsif not tracker.options[:ignore_model_output] and match = has_immediate_model?(out)
      method = match[2]

      unless IGNORE_MODEL_METHODS.include? method
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
          :code => code,
          :confidence => confidence
      end

    else
      false
    end
  end

  #Process an output Sexp
  def process_output exp
    process exp[1].dup
  end

  #Look for calls to raw()
  #Otherwise, ignore
  def process_escaped_output exp
    unless check_for_immediate_xss exp
      if raw_call? exp
        process exp[1][3][1]
      end
    end
    exp
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
        case @matched.type
        when :model
          unless tracker.options[:ignore_model_output]
            message = "Unescaped model attribute"
          end
        when :params
          message = "Unescaped parameter value"
        when :cookies
          message = "Unescaped cookie value"
        end

        if message and not duplicate? exp
          add_result exp

          if exp[1].nil? and @known_dangerous.include? exp[2]
            confidence = CONFIDENCE[:high]
          else
            confidence = CONFIDENCE[:low]
          end

          warn :template => @current_template,
            :warning_type => "Cross Site Scripting", 
            :message => message,
            :code => exp,
            :user_input => @matched.match,
            :confidence => confidence
        end
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
    if (target.nil? and (@ignore_methods.include? method or method.to_s =~ IGNORE_LIKE)) or
      (@matched and @matched.type == :model and IGNORE_MODEL_METHODS.include? method) or
      (target == HAML_HELPERS and method == :html_escape) or
      ((target == URI or target == CGI) and method == :escape) or
      (target == XML_HELPER and method == :escape_xml) or
      (target == FORM_BUILDER and @ignore_methods.include? method) or
      (method.to_s[-1,1] == "?")

      #exp[0] = :ignore #should not be necessary
      @matched = false
    elsif sexp? exp[1] and model_name? exp[1][1]
      @matched = Match.new(:model, exp)
    elsif cookies? exp
      @matched = Match.new(:cookies, exp)
    elsif @inspect_arguments and params? exp
      @matched = Match.new(:params, exp)
    elsif @inspect_arguments
      process args
    end
  end

  #Note that params have been found
  def process_params exp
    @matched = Match.new(:params, exp)
    exp
  end

  #Note that cookies have been found
  def process_cookies exp
    @matched = Match.new(:cookies, exp)
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

  def raw_call? exp
    exp[1].node_type == :call and exp[1][2] == :raw
  end
end
