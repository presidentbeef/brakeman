require 'brakeman/processors/alias_processor'
require 'brakeman/processors/lib/render_helper'

#Processes aliasing in controllers, but includes following
#renders in routes and putting variables into templates
class Brakeman::ControllerAliasProcessor < Brakeman::AliasProcessor
  include Brakeman::RenderHelper

  #If only_method is specified, only that method will be processed,
  #other methods will be skipped.
  #This is for rescanning just a single action.
  def initialize tracker, only_method = nil
    super()
    @only_method = only_method
    @tracker = tracker
    @rendered = false
    @current_class = @current_module = @current_method = nil
  end

  #Processes a class which is probably a controller.
  def process_class exp
    @current_class = class_name(exp[1])
    if @current_module
      @current_class = (@current_module + "::" + @current_class.to_s).to_sym
    end

    process_default exp
  end

  #Processes a method definition, which may include
  #processing any rendered templates.
  def process_methdef exp
    #Skip if instructed to only process a specific method
    #(but don't skip if this method was called from elsewhere)
    return exp if @current_method.nil? and @only_method and @only_method != exp[1]

    is_route = route? exp[1]
    other_method = @current_method
    @current_method = exp[1]
    @rendered = false if is_route

    env.scope do
      set_env_defaults

      if is_route
        before_filter_list(@current_method, @current_class).each do |f|
          process_before_filter f
        end
      end

      process exp[3]

      if is_route and not @rendered
        process_default_render exp
      end
    end

    @current_method = other_method
    exp
  end

  #Look for calls to head()
  def process_call exp
    exp = super

    if exp[2] == :head
      @rendered = true
    end
    exp
  end

  #Check for +respond_to+
  def process_call_with_block exp
    process_default exp

    if exp[1][2] == :respond_to
      @rendered = true
    end

    exp
  end

  #Processes a call to a before filter.
  #Basically, adds any instance variable assignments to the environment.
  #TODO: method arguments?
  def process_before_filter name 
    method = find_method name, @current_class    

    if method.nil?
      warn "[Notice] Could not find filter #{name}" if @tracker.options[:debug]
      return
    end

    processor = Brakeman::AliasProcessor.new
    processor.process_safely(method[3])

    processor.only_ivars.all.each do |variable, value|
      env[variable] = value
    end
  end

  #Processes the default template for the current action
  def process_default_render exp
    process_layout
    process_template template_name, nil
  end

  #Process template and add the current class and method name as called_from info
  def process_template name, args
    super name, args, "#@current_class##@current_method"
  end

  #Turns a method name into a template name
  def template_name name = nil
    name ||= @current_method
    name = name.to_s
    if name.include? "/"
      name
    else
      controller = @current_class.to_s.gsub("Controller", "")
      controller.gsub!("::", "/")
      underscore(controller + "/" + name.to_s)
    end
  end

  #Determines default layout name
  def layout_name
    controller = @tracker.controllers[@current_class]

    return controller[:layout] if controller[:layout]
    return false if controller[:layout] == false

    app_controller = @tracker.controllers[:ApplicationController]

    return app_controller[:layout] if app_controller and app_controller[:layout]

    nil
  end

  #Returns true if the given method name is also a route
  def route? method
    return true if @tracker.routes[:allow_all_actions] or @tracker.options[:assume_all_routes]
    routes = @tracker.routes[@current_class]
    routes and (routes == :allow_all_actions or routes.include? method)
  end

  #Get list of filters, including those that are inherited
  def before_filter_list method, klass
    controller = @tracker.controllers[klass]
    filters = []

    while controller
      filters = get_before_filters(method, controller) + filters

      controller = @tracker.controllers[controller[:parent]]
    end

    filters
  end

  #Returns an array of filter names
  def get_before_filters method, controller
    filters = []
    return filters unless controller[:options]
    filter_list = controller[:options][:before_filters]
    return filters unless filter_list

    filter_list.each do |filter|
      f = before_filter_to_hash filter
      if f[:all] or 
        (f[:only] == method) or
        (f[:only].is_a? Array and f[:only].include? method) or 
        (f[:except] == method) or
        (f[:except].is_a? Array and not f[:except].include? method)

        filters.concat f[:methods]
      end
    end

    filters
  end

  #Returns a before filter as a hash table
  def before_filter_to_hash args
    filter = {}

    #Process args for the uncommon but possible situation
    #in which some variables are used in the filter.
    args.each do |a|
      if sexp? a
        a = process_default a
      end
    end

    filter[:methods] = [args[0][1]]

    args[1..-1].each do |a|
      filter[:methods] << a[1] unless a.node_type == :hash
    end

    if args[-1].node_type == :hash
      option = args[-1][1][1]
      value = args[-1][2]
      case value.node_type
      when :array
        filter[option] = value[1..-1].map {|v| v[1] }
      when :lit, :str
        filter[option] = value[1]
      else
        warn "[Notice] Unknown before_filter value: #{option} => #{value}" if @tracker.options[:debug]
      end
    else
      filter[:all] = true
    end

    filter
  end

  #Finds a method in the given class or a parent class
  def find_method method_name, klass
    return nil if sexp? method_name
    method_name = method_name.to_sym
    controller = @tracker.controllers[klass]
    controller ||= @tracker.libs[klass]

    if klass and controller
      method = controller[:public][method_name]
      method ||= controller[:private][method_name]
      method ||= controller[:protected][method_name]

      if method.nil?
        controller[:includes].each do |included|
          method = find_method method_name, included
          return method if method
        end

        find_method method_name, controller[:parent]
      else
        method
      end
    else
      nil
    end
  end
end
