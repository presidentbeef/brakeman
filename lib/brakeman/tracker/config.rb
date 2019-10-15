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
      @ruby_version = ""
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
      extract_version @gems.dig(name, :version)
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
      !!@gems[name]
    end

    def get_gem name
      @gems[name]
    end

    def set_rails_version version = nil
      version = if version
                  # Only used by Rails2ConfigProcessor right now
                  extract_version(version)
                else
                  gem_version(:rails) || gem_version(:railties)
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
  end
end
