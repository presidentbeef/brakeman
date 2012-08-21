require 'brakeman/checks/check_cross_site_scripting'

#Checks for calls to link_to in versions of Ruby where link_to did not
#escape the first argument.
#
#See https://rails.lighthouseapp.com/projects/8994/tickets/3518-link_to-doesnt-escape-its-input
class Brakeman::CheckLinkTo < Brakeman::CheckCrossSiteScripting
  Brakeman::Checks.add self

  @description = "Checks for XSS in link_to in versions before 3.0"

  def run_check
    return unless version_between?("2.0.0", "2.9.9") and not tracker.config[:escape_html]

    @ignore_methods = Set[:button_to, :check_box, :escapeHTML, :escape_once,
                           :field_field, :fields_for, :h, :hidden_field,
                           :hidden_field, :hidden_field_tag, :image_tag, :label,
                           :mail_to, :radio_button, :select,
                           :submit_tag, :text_area, :text_field,
                           :text_field_tag, :url_encode, :url_for,
                           :will_paginate].merge tracker.options[:safe_methods]

    @known_dangerous = []
    #Ideally, I think this should also check to see if people are setting
    #:escape => false
    methods = tracker.find_call :target => false, :method => :link_to 

    @models = tracker.models.keys
    @inspect_arguments = tracker.options[:check_arguments]

    methods.each do |call|
      process_result call
    end
  end

  def process_result result
    return if duplicate? result

    #Have to make a copy of this, otherwise it will be changed to
    #an ignored method call by the code above.
    call = result[:call] = result[:call].dup

    args = call.args

    @matched = false

    #Skip if no arguments(?) or first argument is a hash
    return if args.first.nil? or hash? args.first

    if version_between? "2.0.0", "2.2.99"
      check_argument result, args.first

      if args.second and not hash? args.second
        check_argument result, args.second
      end
    elsif args.second
      #Only check first argument if there is a second argument
      #in Rails 2.3.x
      check_argument result, args.first
    end
  end

  def check_argument result, exp
    arg = process exp

    if input = has_immediate_user_input?(arg)
      case input.type
      when :params
        message = "Unescaped parameter value in link_to"
      when :cookies
        message = "Unescaped cookie value in link_to"
      else
        message = "Unescaped user input value in link_to"
      end

      add_result result
      warn :result => result,
        :warning_type => "Cross Site Scripting", 
        :message => message,
        :user_input => input.match,
        :confidence => CONFIDENCE[:high],
        :link_path => "link_to"

    elsif not tracker.options[:ignore_model_output] and match = has_immediate_model?(arg)
      method = match[2]

      unless IGNORE_MODEL_METHODS.include? method
        add_result result

        if MODEL_METHODS.include? method or method.to_s =~ /^find_by/
          confidence = CONFIDENCE[:high]
        else
          confidence = CONFIDENCE[:med]
        end

        warn :result => result,
          :warning_type => "Cross Site Scripting", 
          :message => "Unescaped model attribute in link_to",
          :user_input => match,
          :confidence => confidence,
          :link_path => "link_to"
      end

    elsif @matched
      if @matched.type == :model and not tracker.options[:ignore_model_output]
        message = "Unescaped model attribute in link_to"
      elsif @matched.type == :params
        message = "Unescaped parameter value in link_to"
      end

      if message
        add_result result

        warn :result => result, 
          :warning_type => "Cross Site Scripting", 
          :message => message,
          :user_input => @matched.match,
          :confidence => CONFIDENCE[:med],
          :link_path => "link_to"
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

    target = exp.target
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
