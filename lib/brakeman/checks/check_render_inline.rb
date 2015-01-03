class Brakeman::CheckRenderInline < Brakeman::CheckCrossSiteScripting
  Brakeman::Checks.add self

  @description = "Checks for cross site scripting in render calls"

  def run_check
    setup

    tracker.find_call(:target => nil, :method => :render).each do |result|
      check_render result
    end
  end

  def check_render result
    return if duplicate? result
    add_result result

    call = result[:call]

    if node_type? call, :render and
      (call.render_type == :text or call.render_type == :inline)

      render_value = call[2]

      if input = has_immediate_user_input?(render_value)
        warn :result => result,
          :warning_type => "Cross Site Scripting",
          :warning_code => :cross_site_scripting_inline,
          :message => "Unescaped #{friendly_type_of input} rendered inline",
          :code => input.match,
          :confidence => CONFIDENCE[:high]
      elsif input = has_immediate_model?(render_value)
        warn :result => result,
          :warning_type => "Cross Site Scripting",
          :warning_code => :cross_site_scripting_inline,
          :message => "Unescaped model attribute rendered inline",
          :code => input,
          :confidence => CONFIDENCE[:med]
      end
    end
  end
end
