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

  IGNORE_LIKE = /^link_to_|(_path|_tag|_url)$/

  HAML_HELPERS = Sexp.new(:colon2, Sexp.new(:const, :Haml), :Helpers)

  XML_HELPER = Sexp.new(:colon2, Sexp.new(:const, :Erubis), :XmlHelper)

  URI = Sexp.new(:const, :URI)

  CGI = Sexp.new(:const, :CGI)

  FORM_BUILDER = Sexp.new(:call, Sexp.new(:const, :FormBuilder), :new, Sexp.new(:arglist)) 

  #Run check
  def run_check 
    IGNORE_METHODS.merge OPTIONS[:safe_methods]
    @models = tracker.models.keys
    @inspect_arguments = OPTIONS[:check_arguments]

    CheckLinkTo.new(checks, tracker).run_check

    tracker.each_template do |name, template|
      @current_template = template

      template[:outputs].each do |out|
        unless check_for_immediate_xss out
          @matched = false
          @mark = false
          process out
        end
      end
    end
  end

  def check_for_immediate_xss exp
    if exp[0] == :output
      out = exp[1]
    elsif exp[0] == :escaped_output and raw_call? exp
      out = exp[1][3][1]
    end

    type, match = has_immediate_user_input? out

    if type and not duplicate? exp
      add_result exp
      case type
      when :params
        message = "Unescaped parameter value"
      when :cookies
        message = "Unescaped cookie value"
      else
        message = "Unescaped user input value"
      end

      warn :template => @current_template, 
        :warning_type => "Cross Site Scripting",
        :message => message,
        :line => match.line,
        :code => match,
        :confidence => CONFIDENCE[:high]

    elsif not OPTIONS[:ignore_model_output] and match = has_immediate_model?(out)
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
      (target == XML_HELPER and method == :escape_xml) or
      (target == FORM_BUILDER and IGNORE_METHODS.include? method) or
      (method.to_s[-1,1] == "?")

      exp[0] = :ignore
      @matched = false
    elsif sexp? exp[1] and model_name? exp[1][1]

      @matched = :model
    elsif @inspect_arguments and (ALL_PARAMETERS.include?(exp) or params? exp)
      @matched = :params
    elsif @inspect_arguments
      process args
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

  def raw_call? exp
    exp[1].node_type == :call and exp[1][2] == :raw
  end
end

#This _only_ checks calls to link_to
class CheckLinkTo < CheckCrossSiteScripting
  IGNORE_METHODS = IGNORE_METHODS - [:link_to]

  def run_check
    #Ideally, I think this should also check to see if people are setting
    #:escape => false
    methods = tracker.find_call [], :link_to 

    @models = tracker.models.keys
    @inspect_arguments = OPTIONS[:check_arguments]

    methods.each do |call|
      process_result call
    end
  end

  def process_result result
    #Have to make a copy of this, otherwise it will be changed to
    #an ignored method call by the code above.
    call = result[-1] = result[-1].dup

    @matched = false

    return if call[3][1].nil?

    #Only check first argument for +link_to+, as the second
    #will *usually* be a record or escaped.
    first_arg = process call[3][1]

    type, match = has_immediate_user_input? first_arg

    if type
      case type
      when :params
        message = "Unescaped parameter value in link_to"
      when :cookies
        message = "Unescaped cookie value in link_to"
      else
        message = "Unescaped user input value in link_to"
      end

      unless duplicate? result
        add_result result

        warn :result => result,
          :warning_type => "Cross Site Scripting", 
          :message => message,
          :confidence => CONFIDENCE[:high]
      end

    elsif not OPTIONS[:ignore_model_output] and match = has_immediate_model?(first_arg)
      method = match[2]

      unless duplicate? result or IGNORE_MODEL_METHODS.include? method
        add_result result

        if MODEL_METHODS.include? method or method.to_s =~ /^find_by/
          confidence = CONFIDENCE[:high]
        else
          confidence = CONFIDENCE[:med]
        end

        warn :result => result,
          :warning_type => "Cross Site Scripting", 
          :message => "Unescaped model attribute in link_to",
          :confidence => confidence
      end

    elsif @matched
      if @matched == :model and not OPTIONS[:ignore_model_output]
        message = "Unescaped model attribute in link_to"
      elsif @matched == :params
        message = "Unescaped parameter value in link_to"
      end

      if message and not duplicate? result
        add_result result

        warn :result => result, 
          :warning_type => "Cross Site Scripting", 
          :message => message,
          :confidence => CONFIDENCE[:med]
      end
    end
  end

  def process_call exp
    @mark = true
    actually_process_call exp
    exp
  end

  def actually_process_call exp
    return if @matched

    target = exp[1]
    if sexp? target
      target = process target.dup
    end

    #Bare records create links to the model resource,
    #not a string that could have injection
    if model_name? target and context == [:call, :arglist]
      return exp
    end

    super
  end
end
