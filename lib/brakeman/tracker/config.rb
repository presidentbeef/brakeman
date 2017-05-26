require 'brakeman/util'

module Brakeman
  class Config
    include Util

    attr_reader :rails, :tracker
    attr_accessor :rails_version, :ruby_version
    attr_writer :erubis, :escape_html
    attr_reader :gems

    def initialize tracker
      @tracker = tracker
      @rails = {}
      @gems = {}
      @settings = {}
      @escape_html = nil
      @erubis = nil
      @ruby_version = ""
    end

    def allow_forgery_protection?
      @rails[:action_controller] and
        @rails[:action_controller][:allow_forgery_protection] == Sexp.new(:false)
    end

    def erubis?
      @erubis
    end

    def escape_html?
      @escape_html
    end

    def escape_html_entities_in_json?
      #TODO add version-specific information here
      @rails[:active_support] and
        true? @rails[:active_support][:escape_html_entities_in_json]
    end

    def whitelist_attributes?
      @rails[:active_record] and
        @rails[:active_record][:whitelist_attributes] == Sexp.new(:true)
    end

    def gem_version name
      @gems[name] and @gems[name][:version]
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

    def set_rails_version
      # Ignore ~>, etc. when using values from Gemfile
      version = gem_version(:rails) || gem_version(:railties)
      if version and version.match(/(\d+\.\d+\.\d+.*)/)
        @rails_version = $1

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
          end
        end
      end

      if get_gem :rails_xss
        @escape_html = true
        Brakeman.notify "[Notice] Escaping HTML by default"
      end
    end

    def set_ruby_version version
      return unless version.is_a? String

      if version =~ /(\d+\.\d+\.\d+)/
        self.ruby_version = $1
      end
    end

    def session_settings
      @rails[:action_controller] &&
        @rails[:action_controller][:session]
    end

  end
end
