require 'brakeman/checks/check_cross_site_scripting'

#Checks for calls to link_to in versions of Ruby where link_to did not
#escape the first argument.
#
#See https://rails.lighthouseapp.com/projects/8994/tickets/3518-link_to-doesnt-escape-its-input
class Brakeman::CheckLinkTo < Brakeman::CheckCrossSiteScripting
  Brakeman::Checks.add self

  def run_check
    return unless version_between?("2.0.0", "2.9.9") and not tracker.config[:escape_html]

    @ignore_methods = Set.new([:button_to, :check_box, :escapeHTML, :escape_once,
                           :field_field, :fields_for, :h, :hidden_field,
                           :hidden_field, :hidden_field_tag, :image_tag, :label,
                           :mail_to, :radio_button, :select,
                           :submit_tag, :text_area, :text_field,
                           :text_field_tag, :url_encode, :url_for,
                           :will_paginate] ).merge tracker.options[:safe_methods]

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
    #Have to make a copy of this, otherwise it will be changed to
    #an ignored method call by the code above.
    call = result[:call] = result[:call].dup

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

    elsif not tracker.options[:ignore_model_output] and match = has_immediate_model?(first_arg)
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
      if @matched == :model and not tracker.options[:ignore_model_output]
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
