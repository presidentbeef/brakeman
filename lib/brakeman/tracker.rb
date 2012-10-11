require 'set'
require 'brakeman/call_index'
require 'brakeman/checks'
require 'brakeman/report'
require 'brakeman/processors/lib/find_call'
require 'brakeman/processors/lib/find_all_calls'

#The Tracker keeps track of all the processed information.
class Brakeman::Tracker
  attr_accessor :controllers, :templates, :models, :errors,
    :checks, :initializers, :config, :routes, :processor, :libs,
    :template_cache, :options, :filter_cache

  #Place holder when there should be a model, but it is not
  #clear what model it will be.
  UNKNOWN_MODEL = :BrakemanUnresolvedModel

  #Creates a new Tracker.
  #
  #The Processor argument is only used by other Processors
  #that might need to access it.
  def initialize processor = nil, options = {}
    @processor = processor
    @options = options
    @config = {}
    @templates = {}
    @controllers = {}
    #Initialize models with the unknown model so
    #we can match models later without knowing precisely what
    #class they are.
    @models = { UNKNOWN_MODEL => { :name => UNKNOWN_MODEL,
        :parent => nil,
        :includes => [],
        :public => {},
        :private => {},
        :protected => {},
        :options => {} } }
    @routes = {}
    @initializers = {}
    @errors = []
    @libs = {}
    @checks = nil
    @processed = nil
    @template_cache = Set.new
    @filter_cache = {}
    @call_index = nil
  end

  #Add an error to the list. If no backtrace is given,
  #the one from the exception will be used.
  def error exception, backtrace = nil
    backtrace ||= exception.backtrace
    unless backtrace.is_a? Array
      backtrace = [ backtrace ]
    end

    Brakeman.debug exception
    Brakeman.debug backtrace

    @errors << { :error => exception.to_s.gsub("\n", " "), :backtrace => backtrace }
  end

  #Run a set of checks on the current information. Results will be stored
  #in Tracker#checks.
  def run_checks
    @checks = Brakeman::Checks.run_checks(self)
  end

  #Iterate over all methods in controllers and models.
  def each_method
    [self.controllers, self.models].each do |set|
      set.each do |set_name, info|
        [:private, :public, :protected].each do |visibility|
          info[visibility].each do |method_name, definition|
            if definition.node_type == :selfdef
              method_name = "#{definition[1]}.#{method_name}"
            end

            yield definition, set_name, method_name

          end
        end
      end
    end
  end

  #Iterates over each template, yielding the name and the template.
  #Prioritizes templates which have been rendered.
  def each_template
    if @processed.nil?
      @processed, @rest = templates.keys.sort_by{|template| template.to_s}.partition { |k| k.to_s.include? "." }
    end

    @processed.each do |k|
      yield k, templates[k]
    end

    @rest.each do |k|
      yield k, templates[k]
    end
  end

  #Find a method call.
  #
  #Options:
  #  * :target => target name(s)
  #  * :method => method name(s)
  #  * :chained => search in method chains
  #
  #If :target => false or :target => nil, searches for methods without a target.
  #Targets and methods can be specified as a symbol, an array of symbols,
  #or a regular expression.
  #
  #If :chained => true, matches target at head of method chain and method at end.
  #
  #For example:
  #
  #    find_call :target => User, :method => :all, :chained => true
  #
  #could match
  #
  #    User.human.active.all(...)
  #
  def find_call options
    index_call_sites unless @call_index
    @call_index.find_calls options
  end

  #Searches the initializers for a method call
  def check_initializers target, method
    finder = Brakeman::FindCall.new target, method, self

    initializers.sort.each do |name, initializer|
      finder.process_source initializer
    end

    finder.matches
  end

  #Returns a Report with this Tracker's information
  def report
    Brakeman::Report.new(self)
  end

  def index_call_sites
    finder = Brakeman::FindAllCalls.new self

    self.each_method do |definition, set_name, method_name|
      finder.process_source definition, set_name, method_name
    end

    self.each_template do |name, template|
      finder.process_source template[:src], nil, nil, template
    end

    @call_index = Brakeman::CallIndex.new finder.calls
  end

  #Reindex call sites
  #
  #Takes a set of symbols which can include :templates, :models,
  #or :controllers
  #
  #This will limit reindexing to the given sets
  def reindex_call_sites locations
    #If reindexing templates, models, and controllers, just redo
    #everything
    if locations.length == 3
      return index_call_sites
    end

    if locations.include? :templates
      @call_index.remove_template_indexes
    end

    classes_to_reindex = Set.new
    method_sets = []

    if locations.include? :models
      classes_to_reindex.merge self.models.keys
      method_sets << self.models
    end

    if locations.include? :controllers
      classes_to_reindex.merge self.controllers.keys
      method_sets << self.controllers
    end

    @call_index.remove_indexes_by_class classes_to_reindex

    finder = Brakeman::FindAllCalls.new self

    method_sets.each do |set|
      set.each do |set_name, info|
        [:private, :public, :protected].each do |visibility|
          info[visibility].each do |method_name, definition|
            if definition.node_type == :selfdef
              method_name = "#{definition[1]}.#{method_name}"
            end

            finder.process_source definition, set_name, method_name

          end
        end
      end
    end

    if locations.include? :templates
      self.each_template do |name, template|
        finder.process_source template[:src], nil, nil, template
      end
    end

    @call_index.index_calls finder.calls
  end

  #Clear information related to templates.
  #If :only_rendered => true, will delete templates rendered from
  #controllers (but not those rendered from other templates)
  def reset_templates options = { :only_rendered => false }
    if options[:only_rendered]
      @templates.delete_if do |name, template|
        name.to_s.include? "Controller#"
      end
    else
      @templates = {}
    end
    @processed = nil
    @rest = nil
    @template_cache.clear
  end

  #Clear information related to template
  def reset_template name
    name = name.to_sym
    @templates.delete name
    @processed = nil
    @rest = nil
    @template_cache.clear
  end

  #Clear information related to model
  def reset_model path
    model_name = nil

    @models.each do |name, model|
      if model[:file] == path
        model_name = name
        break
      end
    end

    @models.delete model_name
  end

  def reset_controller path
    #Remove from controller
    @controllers.delete_if do |name, controller|
      if controller[:file] == path
        template_matcher = /^#{name}#/

        #Remove templates rendered from this controller
        @templates.each do |template_name, template|
          if template[:caller] and not template[:caller].grep(template_matcher).empty?
            reset_template template_name
            @call_index.remove_template_indexes template_name
          end
        end

        #Remove calls indexed from this controller
        @call_index.remove_indexes_by_class [name]

        true
      end
    end
  end

  #Clear information about routes
  def reset_routes
    @routes = {}
  end
end
