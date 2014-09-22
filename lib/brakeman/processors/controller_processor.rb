require 'brakeman/processors/base_processor'

#Processes controller. Results are put in tracker.controllers
class Brakeman::ControllerProcessor < Brakeman::BaseProcessor
  FORMAT_HTML = Sexp.new(:call, Sexp.new(:lvar, :format), :html)

  def initialize app_tree, tracker
    super(tracker)
    @app_tree = app_tree
    @current_class = nil
    @current_method = nil
    @current_module = nil
    @visibility = :public
    @file_name = nil
  end

  #Use this method to process a Controller
  def process_controller src, file_name = nil
    @file_name = file_name
    process src
  end

  #s(:class, NAME, PARENT, s(:scope ...))
  def process_class exp
    name = class_name(exp.class_name)
    parent = class_name(exp.parent_name)

    #If inside a real controller, treat any other classes as libraries.
    #But if not inside a controller already, then the class may include
    #a real controller, so we can't take this shortcut.
    if @current_class and @current_class[:name].to_s.end_with? "Controller"
      Brakeman.debug "[Notice] Treating inner class as library: #{name}"
      Brakeman::LibraryProcessor.new(@tracker).process_library exp, @file_name
      return exp
    end

    if not name.to_s.end_with? "Controller"
      Brakeman.debug "[Notice] Adding noncontroller as library: #{name}"
      #Set the class to be a module in order to get the right namespacing.
      #Add class to libraries, in case it is needed later (e.g. it's used
      #as a parent class for a controller.)
      #However, still want to process it in this class, so have to set
      #@current_class to this not-really-a-controller thing.
      process_module exp, parent

      return exp
    end

    if @current_class
      outer_class = @current_class
      name = (outer_class[:name].to_s + "::" + name.to_s).to_sym
    end

    if @current_module
      name = (@current_module[:name].to_s + "::" + name.to_s).to_sym
    end

    if @tracker.controllers[name]
      @current_class = @tracker.controllers[name]
      @current_class[:files] << @file_name unless @current_class[:files].include? @file_name
      @current_class[:src][@file_name] = exp
    else
      @current_class = {
        :name => name,
        :parent => parent,
        :includes => [],
        :public => {},
        :private => {},
        :protected => {},
        :options => {:before_filters => []},
        :src => { @file_name => exp },
        :files => [ @file_name ]
      }

      @tracker.controllers[name] = @current_class
    end

    exp.body = process_all! exp.body
    set_layout_name

    if outer_class
      @current_class = outer_class
    else
      @current_class = nil
    end

    exp
  end

  def process_module exp, parent = nil
    name = class_name(exp.module_name)

    if @current_module
      outer_module = @current_module
      name = (outer_module[:name].to_s + "::" + name.to_s).to_sym
    end

    if @current_class
      name = (@current_class[:name].to_s + "::" + name.to_s).to_sym
    end

    if @tracker.libs[name]
      @current_module = @tracker.libs[name]
      @current_module[:files] << @file_name unless @current_module[:files].include? @file_name
      @current_module[:src][@file_name] = exp
    else
      @current_module = {
        :name => name,
        :parent => parent,
        :includes => [],
        :public => {},
        :private => {},
        :protected => {},
        :options => {:before_filters => []},
        :src => { @file_name => exp },
        :files => [ @file_name ]
      }

      @tracker.libs[name] = @current_module
    end

    exp.body = process_all! exp.body

    if outer_module
      @current_module = outer_module
    else
      @current_module = nil
    end

    exp
  end

  #Look for specific calls inside the controller
  def process_call exp
    target = exp.target
    if sexp? target
      target = process target
    end

    method = exp.method
    first_arg = exp.first_arg
    last_arg = exp.last_arg

    #Methods called inside class definition
    #like attr_* and other settings
    if @current_method.nil? and target.nil? and @current_class
      if first_arg.nil? #No args
        case method
        when :private, :protected, :public
          @visibility = method
        when :protect_from_forgery
          @current_class[:options][:protect_from_forgery] = true
        else
          #??
        end
      else
        case method
        when :include
          @current_class[:includes] << class_name(first_arg) if @current_class
        when :before_filter, :append_before_filter, :before_action, :append_before_action
          @current_class[:options][:before_filters] << exp.args
        when :prepend_before_filter, :prepend_before_action
          @current_class[:options][:before_filters].unshift exp.args
        when :layout
          if string? last_arg
            #layout "some_layout"

            name = last_arg.value.to_s
            if @app_tree.layout_exists?(name)
              @current_class[:layout] = "layouts/#{name}"
            else
              Brakeman.debug "[Notice] Layout not found: #{name}"
            end
          elsif node_type? last_arg, :nil, :false
            #layout :false or layout nil
            @current_class[:layout] = false
          end
        else
          @current_class[:options][method] ||= []
          @current_class[:options][method] << exp
        end
      end

      exp
    elsif target == nil and method == :render
      make_render exp
    elsif exp == FORMAT_HTML and context[1] != :iter
      #This is an empty call to
      # format.html
      #Which renders the default template if no arguments
      #Need to make more generic, though.
      call = Sexp.new :render, :default, @current_method
      call.line(exp.line)
      call
    else
      call = make_call target, method, process_all!(exp.args)
      call.line(exp.line)
      call
    end
  end

  #Process method definition and store in Tracker
  def process_defn exp
    name = exp.method_name
    @current_method = name
    res = Sexp.new :methdef, name, exp.formal_args, *process_all!(exp.body)
    res.line(exp.line)
    @current_method = nil

    if @current_class
      @current_class[@visibility][name] = { :src => res, :file => @file_name }
    elsif @current_module
      @current_module[@visibility][name] = { :src => res, :file => @file_name }
    end

    res
  end

  #Process self.method definition and store in Tracker
  def process_defs exp
    name = exp.method_name

    if exp[1].node_type == :self
      if @current_class
        target = @current_class[:name]
      elsif @current_module
        target = @current_module
      else
        target = nil
      end
    else
      target = class_name exp[1]
    end

    @current_method = name
    res = Sexp.new :selfdef, target, name, exp.formal_args, *process_all!(exp.body)
    res.line(exp.line)
    @current_method = nil

    if @current_class
      @current_class[@visibility][name] = { :src => res, :file => @file_name }
    elsif @current_module
      @current_module[@visibility][name] = { :src => res, :file => @file_name }
    end

    res
  end

  #Look for before_filters and add fake ones if necessary
  def process_iter exp
    block_call_name = exp.block_call.method
    if block_call_name == :before_filter  or block_call_name == :before_action
      add_fake_filter exp
    else
      super
    end
  end

  #Sets default layout for renders inside Controller
  def set_layout_name
    return if @current_class[:layout]

    name = underscore(@current_class[:name].to_s.split("::")[-1].gsub("Controller", ''))

    #There is a layout for this Controller
    if @app_tree.layout_exists?(name)
      @current_class[:layout] = "layouts/#{name}"
    end
  end

  #This is to handle before_filter do |controller| ... end
  #
  #We build a new method and process that the same way as usual
  #methods and filters.
  def add_fake_filter exp
    unless @current_class
      Brakeman.debug "Skipping before_filter outside controller: #{exp}"
      return exp
    end

    filter_name = ("fake_filter" + rand.to_s[/\d+$/]).to_sym
    args = exp.block_call.arglist
    args.insert(1, Sexp.new(:lit, filter_name))
    before_filter_call = make_call(nil, :before_filter, args)

    if exp.block_args.length > 1
      block_variable = exp.block_args[1]
    else
      block_variable = :temp
    end

    if node_type? exp.block, :block
      block_inner = exp.block[1..-1]
    else
      block_inner = [exp.block]
    end

    #Build Sexp for filter method
    body = Sexp.new(:lasgn,
                    block_variable,
                    Sexp.new(:call, Sexp.new(:const, @current_class[:name]), :new))

    filter_method = Sexp.new(:defn, filter_name, Sexp.new(:args), body).concat(block_inner).line(exp.line)

    vis = @visibility
    @visibility = :private
    process_defn filter_method
    @visibility = vis
    process before_filter_call
    exp
  end
end
