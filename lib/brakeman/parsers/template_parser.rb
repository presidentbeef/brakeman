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

      begin
        src = case type
              when :erb
                type = :erubis if erubis?
                parse_erb text
              when :haml
                parse_haml text
              when :slim
                parse_slim text
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

    def parse_erb text
      if tracker.config[:escape_html]
        if tracker.options[:rails3]
          require 'brakeman/parsers/rails3_erubis'
          Brakeman::Rails3Erubis.new(text).src
        else
          require 'brakeman/parsers/rails2_xss_plugin_erubis'
          Brakeman::Rails2XSSPluginErubis.new(text).src
        end
      elsif tracker.config[:erubis]
        require 'brakeman/parsers/rails2_erubis'
        Brakeman::ScannerErubis.new(text).src
      else
        require 'erb'
        src = ERB.new(text, nil, "-").src
        src.sub!(/^#.*\n/, '') if Brakeman::Scanner::RUBY_1_9
        src
      end
    end

    def erubis?
      tracker.config[:escape_html] or
      tracker.config[:erubis]
    end

    def parse_haml text
      Brakeman.load_brakeman_dependency 'haml'
      Brakeman.load_brakeman_dependency 'sass'

      Haml::Engine.new(text,
                       :escape_html => !!tracker.config[:escape_html]).precompiled
    end

    def parse_slim text
      Brakeman.load_brakeman_dependency 'slim'

      Slim::Template.new(:disable_capture => true,
                         :generator => Temple::Generators::RailsOutputBuffer) { text }.precompiled_template
    end
  end
end
