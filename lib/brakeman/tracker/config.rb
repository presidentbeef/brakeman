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

    def default_protect_from_forgery?
      if version_between? "5.2.0", "9.9.9"
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

    def whitelist_attributes?
      @rails.dig(:active_record, :whitelist_attributes) == Sexp.new(:true)
    end

    def gem_version name
      @gems.dig(name, :version)
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
      if version and version.match(/(\d+\.\d+(\.\d+.*)?)/)
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

      check_haml_version
    end

    def set_ruby_version version
      return unless version.is_a? String

      if version =~ /(\d+\.\d+\.\d+)/
        self.ruby_version = $1
      end
    end

    #Returns true if low_version <= RAILS_VERSION <= high_version
    #
    #If the Rails version is unknown, returns false.
    def version_between? low_version, high_version, current_version = nil
      current_version ||= rails_version
      return false unless current_version

      version = current_version.split(".").map! { |v| convert_version_number v }
      low_version = low_version.split(".").map! { |v| convert_version_number v }
      high_version = high_version.split(".").map! { |v| convert_version_number v }

      version.each_with_index do |v, i|
        if lower? v, low_version.fetch(i, 0)
          return false
        elsif higher? v, low_version.fetch(i, 0)
          break
        end
      end

      version.each_with_index do |v, i|
        if higher? v, high_version.fetch(i, 0)
          return false
        elsif lower? v, high_version.fetch(i, 0)
          break
        end
      end

      true
    end

    def session_settings
      @rails.dig(:action_controller, :session)
    end

    private

    # Brakeman does not support Haml 5 yet.
    # (https://github.com/presidentbeef/brakeman/issues/1370) Fortunately, Haml
    # 5 doesn't add much new syntax, and brakeman (which uses the haml 4 parser)
    # will parse most Haml 5 files without errors. Therefore, we only print a
    # warning here, instead of raising an error.
    def check_haml_version
      return if supported_haml_version?
      Brakeman.notify <<~EOS
        Brakeman does not fully support Haml 5 yet. Your Gemfile (or gemspec)
        allows Haml 5. Brakeman uses the Haml 4 parser and thus may produce
        errors when parsing Haml 5 syntax. If Brakeman encounters such an error,
        it will be unable to scan that file.
      EOS
    end

    def convert_version_number value
      if value.match(/\A\d+\z/)
        value.to_i
      else
        value
      end
    end

    def lower? lhs, rhs
      if lhs.class == rhs.class
        lhs < rhs
      else
        false
      end
    end

    # Brakeman does not support Haml 5 yet. See `check_haml_version`.
    #
    # This method is messy because all we have is a version `Requirement` (like
    # `~> 5.0.3`, or `> 4.99`) The only way I could think of was to loop over
    # known Haml 5 versions and test whether the `Requirement` is satisfied. I
    # included '5.99.99' in the list so that this method might stand a chance of
    # working in the future.
    def supported_haml_version?
      haml_version = gem_version(:haml)
      return true unless haml_version

      requirement = Gem::Requirement.new(haml_version)
      ['5.99.99', '5.1.1', '5.1.0', '5.0.4', '5.0.3', '5.0.2', '5.0.1', '5.0.0'].none? do |v|
        requirement.satisfied_by?(Gem::Version.new(v))
      end
    end

    def higher? lhs, rhs
      if lhs.class == rhs.class
        lhs > rhs
      else
        false
      end
    end
  end
end
