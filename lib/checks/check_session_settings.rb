require 'checks/base_check'

#Checks for session key length and http_only settings
class CheckSessionSettings < BaseCheck
  Checks.add self

  if OPTIONS[:rails3]
    SessionSettings = Sexp.new(:call, Sexp.new(:colon2, Sexp.new(:const, :Rails3), :Application), :config, Sexp.new(:arglist))
  else
    SessionSettings = Sexp.new(:colon2, Sexp.new(:const, :ActionController), :Base)
  end

  def run_check
    settings = tracker.config[:rails] and
                tracker.config[:rails][:action_controller] and
                tracker.config[:rails][:action_controller][:session]

    check_for_issues settings, "#{OPTIONS[:app_path]}/config/environment.rb"

    if tracker.initializers["session_store.rb"]
      process tracker.initializers["session_store.rb"]
    end
  end

  #Looks for ActionController::Base.session = { ... }
  #in Rails 2.x apps
  def process_attrasgn exp
    if not OPTIONS[:rails3] and exp[1] == SessionSettings and exp[2] == :session=
      check_for_issues exp[3][1], "#{OPTIONS[:app_path]}/config/initializers/session_store.rb"
      exp
    else
      super
    end
  end

  #Looks for Rails3::Application.config.session_store :cookie_store, { ... }
  #in Rails 3.x apps
  def process_call exp
    if OPTIONS[:rails3] and exp[1] == SessionSettings and exp[2] == :session_store
        check_for_issues exp[3][2], "#{OPTIONS[:app_path]}/config/initializers/session_store.rb"
      exp
    else
      super
    end
  end

  private

  def check_for_issues settings, file
    if settings and hash? settings
      hash_iterate settings do |key, value|
        if symbol? key

          if key[1] == :session_http_only and 
            sexp? value and
            value.node_type == :false

            warn :warning_type => "Session Setting",
              :message => "Session cookies should be set to HTTP only",
              :confidence => CONFIDENCE[:high],
              :line => key.line,
              :file => file

          elsif key[1] == :secret and 
            string? value and
            value[1].length < 30

            warn :warning_type => "Session Setting",
              :message => "Session secret should be at least 30 characters long",
              :confidence => CONFIDENCE[:high],
              :line => key.line,
              :file => file

          end
        end
      end
    end
  end
end
