class Brakeman::CheckRenderInlineRCE < Brakeman::CheckCrossSiteScripting
  Brakeman::Checks.add self

  @description = "Checks for template injection in render calls"

  def run_check
    setup

    tracker.find_call(:target => nil, :method => :render).each do |result|
      check_render result
    end
  end

  def check_render result
    return unless original? result

    call = result[:call]

    if node_type? call, :render and call.render_type == :inline
      render_value = call[2]

      if input = has_immediate_user_input?(render_value)
        confidence = :high
      elsif input = has_immediate_model?(render_value)
        confidence = :medium
      end

      if confidence
        warn :result => result,
          :warning_type => "Remote Code Execution",
          :warning_code => :render_inline_template_injection,
          :message => msg("Potential remote code execution via template injection"),
          :user_input => input,
          :confidence => confidence
      end
    end
  end
end
