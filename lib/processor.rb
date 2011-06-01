#Load all files in processors/
Dir.glob("#{File.expand_path(File.dirname(__FILE__))}/processors/*.rb").each { |f| require f.match(/processors.*/)[0] }
require 'tracker'
require 'set'

#Makes calls to the appropriate processor.
#
#The ControllerProcessor, TemplateProcessor, and ModelProcessor will
#update the Tracker with information about what is parsed.
class Processor
  def initialize
    @tracker = Tracker.new self
  end

  def tracked_events
    @tracker
  end

  #Process configuration file source
  def process_config src
    ConfigProcessor.new(@tracker).process_config src
  end

  #Process route file source
  def process_routes src
    RoutesProcessor.new(@tracker).process_routes src
  end

  #Process controller source. +file_name+ is used for reporting
  def process_controller src, file_name
    ControllerProcessor.new(@tracker).process_controller src, file_name
  end

  #Process variable aliasing in controller source and save it in the
  #tracker.
  def process_controller_alias src
    ControllerAliasProcessor.new(@tracker).process src
  end

  #Process a model source
  def process_model src, file_name
    result = ModelProcessor.new(@tracker).process_model src, file_name
    AliasProcessor.new.process result
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
    else
      abort "Unknown template type: #{type} (#{name})"
    end

    #Each template which is rendered is stored separately
    #with a new name.
    if called_from
      name = (name.to_s + "." + called_from.to_s).to_sym
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
    res = AliasProcessor.new.process res
    @tracker.initializers[Pathname.new(name).basename.to_s] = res
  end

  #Process source for a library file
  def process_lib src, file_name
    LibraryProcessor.new(@tracker).process_library src, file_name
  end
end
