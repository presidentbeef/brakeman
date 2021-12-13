require 'brakeman/util'

module Brakeman
  class Config
    include Util

    attr_reader :gems, :rails, :ruby_version, :tracker
    attr_writer :erubis, :escape_html

    def initialize tracker
      @tracker = tracker
      @rails = {}
      @gems = {}
      @settings = {}
      @escape_html = nil
      @erubis = nil
      @ruby_version = nil
      @rails_version = nil
    end

    def default_protect_from_forgery?
      if version_between? "5.2.0.beta1", "9.9.9"
        if @rails.dig(:action_controller, :default_protect_from_forgery) == Sexp.new(:false)
          return false
        else
          return true
        end
      end

      false
    end

    def erubis?
      @erubis
    end

    def escape_html?
      @escape_html
    end

    def escape_html_entities_in_json?
      #TODO add version-specific information here
      true? @rails.dig(:active_support, :escape_html_entities_in_json)
    end

    def escape_filter_interpolations?
      # TODO see if app is actually turning this off itself
      has_gem?(:haml) and
        version_between? "5.0.0", "5.99", gem_version(:haml)
    end

    def whitelist_attributes?
      @rails.dig(:active_record, :whitelist_attributes) == Sexp.new(:true)
    end

    def gem_version name
      extract_version @gems.dig(name.to_sym, :version)
    end

    def add_gem name, version, file, line
      name = name.to_sym
      @gems[name] = {
        :version => version,
        :file => file,
        :line => line
      }
    end

    def has_gem? name
      !!@gems[name.to_sym]
    end

    def get_gem name
      @gems[name.to_sym]
    end

    def set_rails_version version = nil
      version = if version
                  # Only used by Rails2ConfigProcessor right now
                  extract_version(version)
                else
                  gem_version(:rails) ||
                    gem_version(:railties) ||
                    gem_version(:activerecord)
                end

      if version
        @rails_version = version

        if tracker.options[:rails3].nil? and tracker.options[:rails4].nil?
          if @rails_version.start_with? "3"
            tracker.options[:rails3] = true
            Brakeman.notify "[Notice] Detected Rails 3 application"
          elsif @rails_version.start_with? "4"
            tracker.options[:rails3] = true
            tracker.options[:rails4] = true
            Brakeman.notify "[Notice] Detected Rails 4 application"
          elsif @rails_version.start_with? "5"
            tracker.options[:rails3] = true
            tracker.options[:rails4] = true
            tracker.options[:rails5] = true
            Brakeman.notify "[Notice] Detected Rails 5 application"
          elsif @rails_version.start_with? "6"
            tracker.options[:rails3] = true
            tracker.options[:rails4] = true
            tracker.options[:rails5] = true
            tracker.options[:rails6] = true
            Brakeman.notify "[Notice] Detected Rails 6 application"
          elsif @rails_version.start_with? "7"
            tracker.options[:rails3] = true
            tracker.options[:rails4] = true
            tracker.options[:rails5] = true
            tracker.options[:rails6] = true
            tracker.options[:rails7] = true
            Brakeman.notify "[Notice] Detected Rails 7 application"
          end
        end
      end

      if get_gem :rails_xss
        @escape_html = true
        Brakeman.notify "[Notice] Escaping HTML by default"
      end
    end

    def rails_version
      # This needs to be here because Util#rails_version calls Tracker::Config#rails_version
      # but Tracker::Config includes Util...
      @rails_version
    end

    def set_ruby_version version
      @ruby_version = extract_version(version)
    end

    def extract_version version
      return unless version.is_a? String

      version[/\d+\.\d+(\.\d+.*)?/]
    end

    #Returns true if low_version <= RAILS_VERSION <= high_version
    #
    #If the Rails version is unknown, returns false.
    def version_between? low_version, high_version, current_version = nil
      current_version ||= rails_version
      return false unless current_version

      low = Gem::Version.new(low_version)
      high = Gem::Version.new(high_version)
      current = Gem::Version.new(current_version)

      current.between?(low, high)
    end

    def session_settings
      @rails.dig(:action_controller, :session)
    end


    # Set Rails config option value
    # where path is an array of attributes, e.g.
    #
    #   :action_controller, :perform_caching
    #
    # then this will set
    #
    #   rails[:action_controller][:perform_caching] = value
    def set_rails_config value, *path
      config = self.rails

      path[0..-2].each do |o|
        config[o] ||= {}

        option = config[o]

        if not option.is_a? Hash
          Brakeman.debug "[Notice] Skipping config setting: #{path.map(&:to_s).join(".")}"
          return
        end

        config = option
      end

      config[path.last] = value
    end

    # Load defaults based on config.load_defaults value
    # as documented here: https://guides.rubyonrails.org/configuring.html#results-of-config-load-defaults
    def load_rails_defaults
      return unless number? tracker.config.rails[:load_defaults]

      version = tracker.config.rails[:load_defaults].value
      true_value = Sexp.new(:true)
      false_value = Sexp.new(:false)

      if version >= 5.0
        set_rails_config(true_value, :action_controller, :per_form_csrf_tokens)
        set_rails_config(true_value, :action_controller, :forgery_protection_origin_check)
        set_rails_config(true_value, :active_record, :belongs_to_required_by_default)
        # Note: this may need to be changed, because ssl_options is a Hash
        set_rails_config(true_value, :ssl_options, :hsts, :subdomains)
      end

      if version >= 5.1
        set_rails_config(false_value, :assets, :unknown_asset_fallback)
        set_rails_config(true_value, :action_view, :form_with_generates_remote_forms)
      end

      if version >= 5.2
        set_rails_config(true_value, :active_record, :cache_versioning)
        set_rails_config(true_value, :action_dispatch, :use_authenticated_cookie_encryption)
        set_rails_config(true_value, :active_support, :use_authenticated_message_encryption)
        set_rails_config(true_value, :active_support, :use_sha1_digests)
        set_rails_config(true_value, :action_controller, :default_protect_from_forgery)
        set_rails_config(true_value, :action_view, :form_with_generates_ids)
      end

      if version >= 6.0
        set_rails_config(Sexp.new(:lit, :zeitwerk), :autoloader)
        set_rails_config(false_value, :action_view, :default_enforce_utf8)
        set_rails_config(true_value, :action_dispatch, :use_cookies_with_metadata)
        set_rails_config(false_value, :action_dispatch, :return_only_media_type_on_content_type)
        set_rails_config(Sexp.new(:str, 'ActionMailer::MailDeliveryJob'), :action_mailer, :delivery_job)
        set_rails_config(true_value, :active_job, :return_false_on_aborted_enqueue)
        set_rails_config(Sexp.new(:lit, :active_storage_analysis), :active_storage, :queues, :analysis)
        set_rails_config(Sexp.new(:lit, :active_storage_purge), :active_storage, :queues, :purge)
        set_rails_config(true_value, :active_storage, :replace_on_assign_to_many)
        set_rails_config(true_value, :active_record, :collection_cache_versioning)
      end
    end
  end
end
