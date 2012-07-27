require 'brakeman/processors/base_processor'

#Processes controller. Results are put in tracker.controllers
class Brakeman::ControllerProcessor < Brakeman::BaseProcessor
  FORMAT_HTML = Sexp.new(:call, Sexp.new(:lvar, :format), :html, Sexp.new(:arglist))

  def initialize tracker
    super 
    @controller = nil
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

    if @controller
      Brakeman.debug "[Notice] Skipping inner class: #{name}"
      return ignore
    end

    if @current_module
      name = (@current_module.to_s + "::" + name.to_s).to_sym
    end
    @controller = { :name => name,
                    :parent => class_name(exp.parent_name),
                    :includes => [],
                    :public => {},
                    :private => {},
                    :protected => {},
                    :options => {},
                    :src => exp,
                    :file => @file_name }
    @tracker.controllers[@controller[:name]] = @controller
    exp.body = process exp.body
    set_layout_name
    @controller = nil
    exp
  end

  #Look for specific calls inside the controller
  def process_call exp
    target = exp.target
    if sexp? target
      target = process target
    end

    method = exp.method
    args = exp.args

    #Methods called inside class definition
    #like attr_* and other settings
    if @current_method.nil? and target.nil? and @controller
      if args.empty?
        case method
        when :private, :protected, :public
          @visibility = method
        when :protect_from_forgery
          @controller[:options][:protect_from_forgery] = true
        else
          #??
        end
      else
        case method
        when :include
          @controller[:includes] << class_name(args.first) if @controller
        when :before_filter
          @controller[:options][:before_filters] ||= []
          @controller[:options][:before_filters] << args
        when :layout
          if string? args.last
            #layout "some_layout"

            name = args.last.value.to_s
            unless Dir.glob("#{@tracker.options[:app_path]}/app/views/layouts/#{name}.html.{erb,haml}").empty?
              @controller[:layout] = "layouts/#{name}"
            else
              Brakeman.debug "[Notice] Layout not found: #{name}"
            end
          elsif node_type? args.last, :nil, :false
            #layout :false or layout nil
            @controller[:layout] = false
          end
        else
          @controller[:options][method] ||= []
          @controller[:options][method] << exp
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
      call = Sexp.new :call, target, method, process(exp.arglist) #RP 3 TODO
      call.line(exp.line)
      call
    end
  end

  #Process method definition and store in Tracker
  def process_defn exp
    name = exp.meth_name
    @current_method = name
    res = Sexp.new :methdef, name, process(exp[2]), process(exp.body.block)
    res.line(exp.line)
    @current_method = nil
    @controller[@visibility][name] = res unless @controller.nil?

    res
  end

  #Process self.method definition and store in Tracker
  def process_defs exp
    name = exp.meth_name

    if exp[1].node_type == :self
      if @controller
        target = @controller[:name]
      elsif @current_module
        target = @current_module
      else
        target = nil
      end
    else
      target = class_name exp[1]
    end

    @current_method = name
    res = Sexp.new :selfdef, target, name, process(exp[3]), process(exp.body.block)
    res.line(exp.line)
    @current_method = nil
    @controller[@visibility][name] = res unless @controller.nil?

    res
  end

  #Look for before_filters and add fake ones if necessary
  def process_iter exp
    if exp.block_call.name == :before_filter
      add_fake_filter exp
    else
      super
    end
  end

  #Sets default layout for renders inside Controller
  def set_layout_name
    return if @controller[:layout]

    name = underscore(@controller[:name].to_s.split("::")[-1].gsub("Controller", ''))

    #There is a layout for this Controller
    unless Dir.glob("#{@tracker.options[:app_path]}/app/views/layouts/#{name}.html.{erb,haml}").empty?
      @controller[:layout] = "layouts/#{name}"
    end
  end

  #This is to handle before_filter do |controller| ... end
  #
  #We build a new method and process that the same way as usual
  #methods and filters.
  def add_fake_filter exp
    filter_name = ("fake_filter" + rand.to_s[/\d+$/]).to_sym
    args = exp.block_call.arglist
    args.insert(1, Sexp.new(:lit, filter_name))
    before_filter_call = Sexp.new(:call, nil, :before_filter, args)

    if exp.block_args
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
    body = Sexp.new(:scope, 
            Sexp.new(:block,
              Sexp.new(:lasgn, block_variable, 
                Sexp.new(:call, Sexp.new(:const, @controller[:name]), :new, Sexp.new(:arglist)))).concat(block_inner))

    filter_method = Sexp.new(:defn, filter_name, Sexp.new(:args), body).line(exp.line)

    vis = @visibility
    @visibility = :private
    process_defn filter_method
    @visibility = vis
    process before_filter_call
    exp
  end
end
