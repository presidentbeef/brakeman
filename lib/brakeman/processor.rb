#Load all files in processors/
Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/processors/*.rb").each { |f| require f.match(/brakeman\/processors.*/)[0] }
require 'brakeman/tracker'
require 'set'
require 'pathname'

module Brakeman
  #Makes calls to the appropriate processor.
  #
  #The ControllerProcessor, TemplateProcessor, and ModelProcessor will
  #update the Tracker with information about what is parsed.
  class Processor
    include Util

    def initialize(app_tree, options)
      @app_tree = app_tree
      @tracker = Tracker.new(@app_tree, self, options)
    end

    def tracked_events
      @tracker
    end

    #Process configuration file source
    def process_config src
      ConfigProcessor.new(@tracker).process_config src
    end

    #Process Gemfile
    def process_gems src, gem_lock = nil
      GemProcessor.new(@tracker).process_gems src, gem_lock
    end

    #Process route file source
    def process_routes src
      RoutesProcessor.new(@tracker).process_routes src
    end

    #Process controller source. +file_name+ is used for reporting
    def process_controller src, file_name
      if contains_class? src
        ControllerProcessor.new(@app_tree, @tracker).process_controller src, file_name
      else
        LibraryProcessor.new(@tracker).process_library src, file_name
      end
    end

    #Process variable aliasing in controller source and save it in the
    #tracker.
    def process_controller_alias name, src, only_method = nil
      ControllerAliasProcessor.new(@app_tree, @tracker, only_method).process_controller name, src
    end

    #Process a model source
    def process_model src, file_name
      result = ModelProcessor.new(@tracker).process_model src, file_name
      AliasProcessor.new(@tracker).process_all result if result
    end

    #Process either an ERB or HAML template
    def process_template name, src, type, called_from = nil, file_name = nil
      case type
      when :erb
        result = ErbTemplateProcessor.new(@tracker, name, called_from, file_name).process src
      when :haml
        result = HamlTemplateProcessor.new(@tracker, name, called_from, file_name).process src
      when :erubis
        result = ErubisTemplateProcessor.new(@tracker, name, called_from, file_name).process src
      when :slim
        result = SlimTemplateProcessor.new(@tracker, name, called_from, file_name).process src
      else
        abort "Unknown template type: #{type} (#{name})"
      end

      #Each template which is rendered is stored separately
      #with a new name.
      if called_from
        name = ("#{name}.#{called_from}").to_sym
      end

      @tracker.templates[name][:src] = result
      @tracker.templates[name][:type] = type
    end

    #Process any calls to render() within a template
    def process_template_alias template
      TemplateAliasProcessor.new(@tracker, template).process_safely template[:src]
    end

    #Process source for initializing files
    def process_initializer name, src
      res = BaseProcessor.new(@tracker).process src
      res = AliasProcessor.new(@tracker).process res
      @tracker.initializers[Pathname.new(name).basename.to_s] = res
    end

    #Process source for a library file
    def process_lib src, file_name
      LibraryProcessor.new(@tracker).process_library src, file_name
    end
  end
end
