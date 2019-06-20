require 'brakeman/checks/base_check'

class Brakeman::CheckReverseTabnabbing < Brakeman::BaseCheck
  Brakeman::Checks.add_optional self

  @description = "Checks for reverse tabnabbing cases on 'link_to' calls"

  def run_check
    calls = tracker.find_call :methods => :link_to
    calls.each do |call|
      process_result call
    end
  end

  def process_result result
    return unless original? result and result[:call].last_arg

    html_opts = result[:call].last_arg
    return unless hash? html_opts

    target = hash_access html_opts, :target
    return unless target && string?(target) && target.value == "_blank"

    target_url = result[:call].second_arg

    rel = hash_access html_opts, :rel
    confidence = :medium

    if rel && string?(rel) then
      rel = rel.value
      return if rel.include?("noopener") && rel.include?("noreferrer")

      if rel.include?("noopener") ^ rel.include?("noreferrer") then
        confidence = :weak
      end
    end

    warn :result => result,
      :warning_type => "Reverse Tabnabbing",
      :warning_code => :reverse_tabnabbing,
      :message => "The newly opened tab can control the parent tab's " +
                  "location, thus redirect it to a phishing page",
      :confidence => confidence
  end
end
