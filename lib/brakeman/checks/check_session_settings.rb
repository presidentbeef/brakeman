require 'brakeman/checks/base_check'

#Checks for session key length and http_only settings
class Brakeman::CheckSessionSettings < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Checks for session key length and http_only settings"

  def initialize *args
    super

    unless tracker.options[:rails3]
      @session_settings = Sexp.new(:colon2, Sexp.new(:const, :ActionController), :Base)
    else
      @session_settings = nil
    end
  end

  def run_check
    settings = tracker.config[:rails][:action_controller] &&
               tracker.config[:rails][:action_controller][:session]

    check_for_issues settings, "#{tracker.app_path}/config/environment.rb"

    ["session_store.rb", "secret_token.rb"].each do |file|
      if tracker.initializers[file] and not ignored? file
        process tracker.initializers[file]
      end
    end
  end

  #Looks for ActionController::Base.session = { ... }
  #in Rails 2.x apps
  #
  #and App::Application.config.secret_token =
  #in Rails 3.x apps
  #
  #and App::Application.config.secret_key_base =
  #in Rails 4.x apps
  def process_attrasgn exp
    if not tracker.options[:rails3] and exp.target == @session_settings and exp.method == :session=
      check_for_issues exp.first_arg, "#{tracker.app_path}/config/initializers/session_store.rb"
    end

    if tracker.options[:rails3] and settings_target?(exp.target) and
      (exp.method == :secret_token= or exp.method == :secret_key_base=) and string? exp.first_arg

      warn_about_secret_token exp, "#{tracker.app_path}/config/initializers/secret_token.rb"
    end

    exp
  end

  #Looks for Rails3::Application.config.session_store :cookie_store, { ... }
  #in Rails 3.x apps
  def process_call exp
    if tracker.options[:rails3] and settings_target?(exp.target) and exp.method == :session_store
      check_for_rails3_issues exp.second_arg, "#{tracker.app_path}/config/initializers/session_store.rb"
    end

    exp
  end

  private

  def settings_target? exp
    call? exp and
    exp.method == :config and
    node_type? exp.target, :colon2 and
    exp.target.rhs == :Application
  end

  def check_for_issues settings, file
    if settings and hash? settings
      if value = (hash_access(settings, :session_http_only) ||
                  hash_access(settings, :http_only) ||
                  hash_access(settings, :httponly))

        if false? value
          warn_about_http_only value, file
        end
      end

      if value = hash_access(settings, :secret)
        if string? value
          warn_about_secret_token value, file
        end
      end
    end
  end

  def check_for_rails3_issues settings, file
    if settings and hash? settings
      if value = hash_access(settings, :httponly)
        if false? value
          warn_about_http_only value, file
        end
      end

      if value = hash_access(settings, :secure)
        if false? value
          warn_about_secure_only value, file
        end
      end
    end
  end

  def warn_about_http_only value, file
    warn :warning_type => "Session Setting",
      :warning_code => :http_cookies,
      :message => "Session cookies should be set to HTTP only",
      :confidence => CONFIDENCE[:high],
      :line => value.line,
      :file => file

  end

  def warn_about_secret_token value, file
    warn :warning_type => "Session Setting",
      :warning_code => :session_secret,
      :message => "Session secret should not be included in version control",
      :confidence => CONFIDENCE[:high],
      :line => value.line,
      :file => file
  end

  def warn_about_secure_only value, file
    warn :warning_type => "Session Setting",
      :warning_code => :secure_cookies,
      :message => "Session cookie should be set to secure only",
      :confidence => CONFIDENCE[:high],
      :line => value.line,
      :file => file
  end

  def ignored? file
    [".", "config", "config/initializers"].each do |dir|
      ignore_file = "#{dir}/.gitignore"
      if @app_tree.exists? ignore_file
        input = @app_tree.read(ignore_file)

        return true if input.include? file
      end
    end

    false
  end
end
