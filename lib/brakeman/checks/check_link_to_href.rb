require 'brakeman/checks/check_cross_site_scripting'

#Checks for calls to link_to which pass in potentially hazardous data
#to the second argument.  While this argument must be html_safe to not break 
#the html, it must also be url safe as determined by calling a 
#:url_safe_method.  This prevents attacks such as javascript:evil() or 
#data:<encoded XSS> which is html_safe, but not safe as an href
#Props to Nick Green for the idea.
class Brakeman::CheckLinkToHref < Brakeman::CheckLinkTo
  Brakeman::Checks.add self
                        
  @description = "Checks to see if values used for hrefs are sanitized using a :url_safe_method to protect against javascript:/data: XSS"

  def run_check
    @ignore_methods = Set[:button_to, :check_box,
                           :field_field, :fields_for, :hidden_field,
                           :hidden_field, :hidden_field_tag, :image_tag, :label,
                           :mail_to, :radio_button, :select,
                           :submit_tag, :text_area, :text_field,
                           :text_field_tag, :url_encode, :url_for,
                           :will_paginate].merge(tracker.options[:url_safe_methods] || [])

    @models = tracker.models.keys
    @inspect_arguments = tracker.options[:check_arguments]

    methods = tracker.find_call :target => false, :method => :link_to 
    methods.each do |call|
      process_result call
    end
  end

  def process_result result
    #Have to make a copy of this, otherwise it will be changed to
    #an ignored method call by the code above.
    call = result[:call] = result[:call].dup
    @matched = false
    url_arg = process call.second_arg

    #Ignore situations where the href is an interpolated string
    #with something before the user input
    return if node_type?(url_arg, :string_interp) && !url_arg[1].chomp.empty?


    if input = has_immediate_user_input?(url_arg)
      message = "Unsafe #{friendly_type_of input} in link_to href"

      unless duplicate? result
        add_result result
        warn :result => result,
          :warning_type => "Cross Site Scripting", 
          :warning_code => :xss_link_to_href,
          :message => message,
          :user_input => input.match,
          :confidence => CONFIDENCE[:high],
          :link_path => "link_to_href"
      end
    elsif has_immediate_model? url_arg

      # Decided NOT warn on models.  polymorphic_path is called it a model is 
      # passed to link_to (which passes it to url_for)

    elsif array? url_arg
      # Just like models, polymorphic path/url is called if the argument is 
      # an array      

    elsif hash? url_arg

      # url_for uses the key/values pretty carefully and I don't see a risk.
      # IF you have default routes AND you accept user input for :controller
      # and :only_path, then MAYBE you could trigger a javascript:/data: 
      # attack. 

    elsif @matched
      if @matched.type == :model and not tracker.options[:ignore_model_output]
        message = "Unsafe model attribute in link_to href"
      elsif @matched.type == :params
        message = "Unsafe parameter value in link_to href"
      end

      if message and not duplicate? result
        add_result result
        warn :result => result, 
          :warning_type => "Cross Site Scripting", 
          :warning_code => :xss_link_to_href,
          :message => message,
          :user_input => @matched.match,
          :confidence => CONFIDENCE[:med],
          :link_path => "link_to_href"
      end
    end
  end
end
