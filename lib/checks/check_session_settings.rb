require 'checks/base_check'

class CheckSessionSettings < BaseCheck
  Checks.add self

  SessionSettings = Sexp.new(:colon2, Sexp.new(:const, :ActionController), :Base)

  def run_check
    settings = tracker.config[:rails] and
                tracker.config[:rails][:action_controller] and
                tracker.config[:rails][:action_controller][:session]

    check_for_issues settings

    if tracker.initializers["session_store.rb"]
      process tracker.initializers["session_store.rb"]
    end
  end

  def process_attrasgn exp
    if exp[1] == SessionSettings and exp[2] == :session= and
      hash? exp[3][1] 

      check_for_issues exp[3][1]
    end

    exp
  end

  private

  def check_for_issues settings
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
