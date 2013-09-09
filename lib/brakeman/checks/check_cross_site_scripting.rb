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

  FORM_BUILDER = Sexp.new(:call, Sexp.new(:const, :FormBuilder), :new)

  #Run check
  def run_check
    @ignore_methods = Set[:button_to, :check_box, :content_tag, :escapeHTML, :escape_once,
                           :field_field, :fields_for, :h, :hidden_field,
                           :hidden_field, :hidden_field_tag, :image_tag, :label,
                           :link_to, :mail_to, :radio_button, :select,
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

    json_escape_on = false
    initializers = tracker.check_initializers :ActiveSupport, :escape_html_entities_in_json=
    initializers.each {|result| json_escape_on = true?(result.call.first_arg) }

    if tracker.config[:rails][:active_support] and
      true? tracker.config[:rails][:active_support][:escape_html_entities_in_json]

        json_escape_on = true
    elsif version_between? "4.0.0", "5.0.0"
      json_escape_on = true
    end

    if !json_escape_on or version_between? "0.0.0", "2.0.99"
      @known_dangerous << :to_json
      Brakeman.debug("Automatic to_json escaping not enabled, consider to_json dangerous")
    else
      @safe_input_attributes << :to_json
      Brakeman.debug("Automatic to_json escaping is enabled.")
    end

    tracker.each_template do |name, template|
      Brakeman.debug "Checking #{name} for XSS"

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
    return :duplicate if duplicate? exp

    if exp.node_type == :output
      out = exp.value
    elsif exp.node_type == :escaped_output and raw_call? exp
      out = exp.value.first_arg
    end

    if input = has_immediate_user_input?(out)
      add_result exp

      message = "Unescaped #{friendly_type_of input}"

      warn :template => @current_template,
        :warning_type => "Cross Site Scripting",
        :warning_code => :cross_site_scripting,
        :message => message,
        :code => input.match,
        :confidence => CONFIDENCE[:high]

    elsif not tracker.options[:ignore_model_output] and match = has_immediate_model?(out)
      method = if call? match
                 match.method
               else
                 nil
               end

      unless IGNORE_MODEL_METHODS.include? method
        add_result exp

        if likely_model_attribute? match
          confidence = CONFIDENCE[:high]
        else
          confidence = CONFIDENCE[:med]
        end

        message = "Unescaped model attribute"
        link_path = "cross_site_scripting"
        warning_code = :cross_site_scripting

        if node_type?(out, :call, :attrasgn) && out.method == :to_json
          message += " in JSON hash"
          link_path += "_to_json"
          warning_code = :xss_to_json
        end

        code = if match == out
                 nil
               else
                 match
               end

        warn :template => @current_template,
          :warning_type => "Cross Site Scripting",
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

  #Call already involves a model, but might not be acting on a record
  def likely_model_attribute? exp
    return false unless call? exp

    method = exp.method

    if MODEL_METHODS.include? method or method.to_s.start_with? "find_by_"
      true
    else
      likely_model_attribute? exp.target
    end
  end

  #Process an output Sexp
  def process_output exp
    process exp.value.dup
  end

  #Look for calls to raw()
  #Otherwise, ignore
  def process_escaped_output exp
    unless check_for_immediate_xss exp
      if raw_call? exp and not duplicate? exp
        process exp.value.first_arg
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
        unless @matched.type and tracker.options[:ignore_model_output]
          message = "Unescaped #{friendly_type_of @matched}"
        end

        if message and not duplicate? exp
          add_result exp

          link_path = "cross_site_scripting"
          if @known_dangerous.include? exp.method
            confidence = CONFIDENCE[:high]
            if exp.method == :to_json
              message += " in JSON hash"
              link_path += "_to_json"
            end
          else
            confidence = CONFIDENCE[:low]
          end

          warn :template => @current_template,
            :warning_type => "Cross Site Scripting",
            :warning_code => :xss_to_json,
            :message => message,
            :code => exp,
            :user_input => @matched.match,
            :confidence => confidence,
            :link_path => link_path
        end
      end

      @mark = @matched = false
    end

    exp
  end

  def actually_process_call exp
    return if @matched
    target = exp.target
    if sexp? target
      target = process target
    end

    method = exp.method

    #Ignore safe items
    if ignore_call? target, method
      @matched = false
    elsif sexp? target and model_name? target[1] #TODO: use method call?
      @matched = Match.new(:model, exp)
    elsif cookies? exp
      @matched = Match.new(:cookies, exp)
    elsif @inspect_arguments and params? exp
      @matched = Match.new(:params, exp)
    elsif @inspect_arguments
      process_call_args exp
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
    process exp.then_clause if sexp? exp.then_clause
    process exp.else_clause if sexp? exp.else_clause
    exp
  end

  def raw_call? exp
    exp.value.node_type == :call and exp.value.method == :raw
  end

  def ignore_call? target, method
    ignored_method?(target, method) or
    safe_input_attribute?(target, method) or
    ignored_model_method?(method) or
    form_builder_method?(target, method) or
    haml_escaped?(target, method) or
    boolean_method?(method) or
    cgi_escaped?(target, method) or
    xml_escaped?(target, method)
  end

  def ignored_model_method? method
    @matched and
    @matched.type == :model and
    IGNORE_MODEL_METHODS.include? method
  end

  def ignored_method? target, method
    target.nil? and
    (@ignore_methods.include? method or method.to_s =~ IGNORE_LIKE)
  end

  def cgi_escaped? target, method
    method == :escape and
    (target == URI or target == CGI)
  end

  def haml_escaped? target, method
    method == :html_escape and target == HAML_HELPERS
  end

  def xml_escaped? target, method
    method == :escape_xml and target == XML_HELPER
  end

  def form_builder_method? target, method
    target == FORM_BUILDER and @ignore_methods.include? method
  end

  def safe_input_attribute? target, method
    target and @safe_input_attributes.include? method
  end

  def boolean_method? method
    method.to_s.end_with? "?"
  end
end
