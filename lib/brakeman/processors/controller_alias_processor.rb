require 'brakeman/processors/alias_processor'
require 'brakeman/processors/lib/render_helper'
require 'brakeman/processors/lib/render_path'
require 'brakeman/processors/lib/find_return_value'

#Processes aliasing in controllers, but includes following
#renders in routes and putting variables into templates
class Brakeman::ControllerAliasProcessor < Brakeman::AliasProcessor
  include Brakeman::RenderHelper

  #If only_method is specified, only that method will be processed,
  #other methods will be skipped.
  #This is for rescanning just a single action.
  def initialize app_tree, tracker, only_method = nil
    super tracker
    @app_tree = app_tree
    @only_method = only_method
    @rendered = false
    @current_class = @current_module = @current_method = nil
    @method_cache = {} #Cache method lookups
  end

  def process_controller name, src, file
    if not node_type? src, :class
      Brakeman.debug "#{name} is not a class, it's a #{src.node_type}"
      return
    else
      @current_class = name
      @file = file

      process_default src

      process_mixins
    end
  end

  #Process modules mixed into the controller, in case they contain actions.
  def process_mixins
    controller = @tracker.controllers[@current_class]

    controller.includes.each do |i|
      mixin = @tracker.libs[i]

      next unless mixin

      #Process methods in alphabetical order for consistency
      methods = mixin.methods_public.keys.map { |n| n.to_s }.sort.map { |n| n.to_sym }

      methods.each do |name|
        #Need to process the method like it was in a controller in order
        #to get the renders set
        processor = Brakeman::ControllerProcessor.new(@app_tree, @tracker)
        method = mixin.get_method(name)[:src].deep_clone

        if node_type? method, :defn
          method = processor.process_defn method
        else
          #Should be a defn, but this will catch other cases
          method = processor.process method
        end

        @file = mixin.file
        #Then process it like any other method in the controller
        process method
      end
    end
  end

  #Skip it, must be an inner class
  def process_class exp
    exp
  end

  #Processes a method definition, which may include
  #processing any rendered templates.
  def process_defn exp
    meth_name = exp.method_name

    Brakeman.debug "Processing #{@current_class}##{meth_name}"

    #Skip if instructed to only process a specific method
    #(but don't skip if this method was called from elsewhere)
    return exp if @current_method.nil? and @only_method and @only_method != meth_name

    is_route = route? meth_name
    other_method = @current_method
    @current_method = meth_name
    @rendered = false if is_route

    meth_env do
      if is_route
        before_filter_list(@current_method, @current_class).each do |f|
          process_before_filter f
        end
      end

      process_all exp.body

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
    return exp unless call? exp

    method = exp.method

    if method == :head
      @rendered = true
    elsif @tracker.options[:interprocedural] and
      @current_method and (exp.target.nil? or exp.target.node_type == :self)

      exp = get_call_value(exp)
    end

    exp
  end

  #Check for +respond_to+
  def process_iter exp
    super

    if call? exp.block_call and exp.block_call.method == :respond_to
      @rendered = true
    end

    exp
  end

  #Processes a call to a before filter.
  #Basically, adds any instance variable assignments to the environment.
  #TODO: method arguments?
  def process_before_filter name
    filter = find_method name, @current_class

    if filter.nil?
      Brakeman.debug "[Notice] Could not find filter #{name}"
      return
    end

    method = filter[:method]

    if ivars = @tracker.filter_cache[[filter[:controller], name]]
      ivars.each do |variable, value|
        env[variable] = value
      end
    else
      processor = Brakeman::AliasProcessor.new @tracker
      processor.process_safely(method.body_list, only_ivars(:include_request_vars))

      ivars = processor.only_ivars(:include_request_vars).all

      @tracker.filter_cache[[filter[:controller], name]] = ivars

      ivars.each do |variable, value|
        env[variable] = value
      end
    end
  end

  #Processes the default template for the current action
  def process_default_render exp
    process_layout
    process_template template_name, nil, nil, nil
  end

  #Process template and add the current class and method name as called_from info
  def process_template name, args, _, line
    # If line is null, assume implicit render and set the end of the action
    # method as the line number
    if line.nil? and controller = @tracker.controllers[@current_class]
      if meth = controller.get_method(@current_method)
        line = meth[:src] && meth[:src].last && meth[:src].last.line
        line += 1
      end
    end

    render_path = Brakeman::RenderPath.new.add_controller_render(@current_class, @current_method, line, relative_path(@file))
    super name, args, render_path, line
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

    return controller.layout if controller.layout
    return false if controller.layout == false

    app_controller = @tracker.controllers[:ApplicationController]

    return app_controller.layout if app_controller and app_controller.layout

    nil
  end

  #Returns true if the given method name is also a route
  def route? method
    if @tracker.routes[:allow_all_actions] or @tracker.options[:assume_all_routes]
      true
    else
      routes = @tracker.routes[@current_class]
      routes and (routes.include? :allow_all_actions or routes.include? method)
    end
  end

  #Get list of filters, including those that are inherited
  def before_filter_list method, klass
    controller = @tracker.controllers[klass]

    if controller
      controller.before_filter_list self, method
    else
      []
    end
  end

  #Finds a method in the given class or a parent class
  #
  #Returns nil if the method could not be found.
  #
  #If found, returns hash table with controller name and method sexp.
  def find_method method_name, klass
    return nil if sexp? method_name
    method_name = method_name.to_sym

    if method = @method_cache[method_name]
      return method
    end

    controller = @tracker.controllers[klass]
    controller ||= @tracker.libs[klass]

    if klass and controller
      method = controller.get_method method_name

      if method.nil?
        controller.includes.each do |included|
          method = find_method method_name, included
          if method
            @method_cache[method_name] = method
            return method
          end
        end

        @method_cache[method_name] = find_method method_name, controller.parent
      else
        @method_cache[method_name] = { :controller => controller.name, :method => method[:src] }
      end
    else
      nil
    end
  end
end
