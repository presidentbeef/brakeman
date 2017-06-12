module Brakeman
  class TemplateParser
    include Brakeman::Util
    attr_reader :tracker
    KNOWN_TEMPLATE_EXTENSIONS = /.*\.(erb|haml|rhtml|slim)$/

    TemplateFile = Struct.new(:path, :ast, :name, :type)

    def initialize tracker, file_parser
      @tracker = tracker
      @file_parser = file_parser
      @file_parser.file_list[:templates] ||= []
    end

    def parse_template path, text
      type = path.match(KNOWN_TEMPLATE_EXTENSIONS)[1].to_sym
      type = :erb if type == :rhtml
      name = template_path_to_name path
      Brakeman.debug "Parsing #{path}"

      begin
        src = case type
              when :erb
                type = :erubis if erubis?
                parse_erb path, text
              when :haml
                parse_haml path, text
              when :slim
                parse_slim path, text
              else
                tracker.error "Unknown template type in #{path}"
                nil
              end

        if src and ast = @file_parser.parse_ruby(src, path)
          @file_parser.file_list[:templates] << TemplateFile.new(path, ast, name, type)
        end
      rescue Racc::ParseError => e
        tracker.error e, "could not parse #{path}"
      rescue Haml::Error => e
        tracker.error e, ["While compiling HAML in #{path}"] << e.backtrace
      rescue StandardError, LoadError => e
        tracker.error e.exception(e.message + "\nWhile processing #{path}"), e.backtrace
      end

      nil
    end

    def parse_erb path, text
      if tracker.config.escape_html?
        if tracker.options[:rails3]
          require 'brakeman/parsers/rails3_erubis'
          Brakeman::Rails3Erubis.new(text, :filename => path).src
        else
          require 'brakeman/parsers/rails2_xss_plugin_erubis'
          Brakeman::Rails2XSSPluginErubis.new(text, :filename => path).src
        end
      elsif tracker.config.erubis?
        require 'brakeman/parsers/rails2_erubis'
        Brakeman::ScannerErubis.new(text, :filename => path).src
      else
        require 'erb'
        src = ERB.new(text, nil, path).src
        src.sub!(/^#.*\n/, '') if Brakeman::Scanner::RUBY_1_9
        src
      end
    end

    def erubis?
      tracker.config.escape_html? or
        tracker.config.erubis?
    end

    def parse_haml path, text
      Brakeman.load_brakeman_dependency 'haml'
      Brakeman.load_brakeman_dependency 'sass'

      Haml::Engine.new(text,
                       :filename => path,
                       :escape_html => tracker.config.escape_html?).precompiled.gsub(/([^\\])\\n/, '\1')
    end

    def parse_slim path, text
      Brakeman.load_brakeman_dependency 'slim'

      Slim::Template.new(path,
                         :disable_capture => true,
                         :generator => Temple::Generators::RailsOutputBuffer) { text }.precompiled_template
    end

    def self.parse_inline_erb tracker, text
      fp = Brakeman::FileParser.new(nil, nil)
      tp = self.new(tracker, fp)
      src = tp.parse_erb '_inline_', text
      type = tp.erubis? ? :erubis : :erb

      return type, fp.parse_ruby(src, "_inline_")
    end
  end
end
