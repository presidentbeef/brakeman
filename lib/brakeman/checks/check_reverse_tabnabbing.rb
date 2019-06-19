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
    return unless original? result and result[:call].third_arg

    html_opts = result[:call].third_arg
    _, target = hash_access html_opts, :target
    _, rel = hash_access html_opts, :rel
    return unless target

    target_url = result[:call].second_arg

    # `_url` and `_path` lead to urls on to the same origin.
    # That means that an adversary would need to run javascript on
    # the victim application's domain. If that is the case, the adversary
    # already has the ability to redirect the victim user anywhere.
    if target_url[0] == :call then
      func_s = target_url.method.to_s
      return unless !func_s.end_with?("url") && !func_s.end_with?("path")
    end

    if target == "_blank" && (!rel || (rel && !rel.include?("noopener"))) then
      warn :result => result,
        :warning_type => "Reverse Tabnabbing",
        :warning_code => :reverse_tabnabbing,
        :message => "The newly opened tab can control the parent tab's " +
                    "location, thus redirect it to a phishing page",
        :confidence => :weak
    end
  end
end
