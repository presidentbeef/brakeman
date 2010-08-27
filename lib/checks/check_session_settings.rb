require 'checks/base_check'

class CheckSessionSettings < BaseCheck
  Checks.add self

  def run_check
    settings = tracker.config[:rails] and
                tracker.config[:rails][:action_controller] and
                tracker.config[:rails][:action_controller][:session]

    if settings and hash? settings
      hash_iterate settings do |key, value|
        if symbol? key

          if key[1] == :session_http_only and 
            sexp? value and
            value.node_type == :false

            warn :warning_type => "Session Setting",
              :message => "Session cookies should be set to HTTP only",
              :confidence => CONFIDENCE[:high]

          elsif key[1] == :secret and 
            string? value and
            value[1].length < 30

            warn :warning_type => "Session Setting",
              :message => "Session secret should be at least 30 characters long",
              :confidence => CONFIDENCE[:high]

          end
        end
      end
    end
  end
end
