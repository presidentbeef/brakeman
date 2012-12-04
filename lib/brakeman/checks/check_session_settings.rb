require 'brakeman/checks/base_check'

#Checks for session key length and http_only settings
class Brakeman::CheckSessionSettings < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for session key length and http_only settings"

  def initialize *args
    super

    if tracker.options[:rails3]
      @session_settings = Sexp.new(:call, Sexp.new(:colon2, Sexp.new(:const, :Rails3), :Application), :config)
    else
      @session_settings = Sexp.new(:colon2, Sexp.new(:const, :ActionController), :Base)
    end
  end

  def run_check
    settings = tracker.config[:rails] and
                tracker.config[:rails][:action_controller] and
                tracker.config[:rails][:action_controller][:session]

    check_for_issues settings, "#{tracker.options[:app_path]}/config/environment.rb"

    if tracker.initializers["session_store.rb"]
      process tracker.initializers["session_store.rb"]
    end
  end

  #Looks for ActionController::Base.session = { ... }
  #in Rails 2.x apps
  def process_attrasgn exp
    if not tracker.options[:rails3] and exp.target == @session_settings and exp.method == :session=
      check_for_issues exp.first_arg, "#{tracker.options[:app_path]}/config/initializers/session_store.rb"
    end
      
    exp
  end

  #Looks for Rails3::Application.config.session_store :cookie_store, { ... }
  #in Rails 3.x apps
  def process_call exp
    if tracker.options[:rails3] and exp.target == @session_settings and exp.method == :session_store
        check_for_issues exp.args.second, "#{tracker.options[:app_path]}/config/initializers/session_store.rb"
    end
      
    exp
  end

  private

  def check_for_issues settings, file
    if settings and hash? settings
      if value = hash_access(settings, :session_http_only)
        if false? value
          warn :warning_type => "Session Setting",
            :message => "Session cookies should be set to HTTP only",
            :confidence => CONFIDENCE[:high],
            :line => value.line,
            :file => file
        end
      end

      if value = hash_access(settings, :secret)
        if string? value and value.value.length < 30

          warn :warning_type => "Session Setting",
            :message => "Session secret should be at least 30 characters long",
            :confidence => CONFIDENCE[:high],
            :line => value.line,
            :file => file

        end
      end
    end
  end
end
