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
    if @controller
      Brakeman.debug "[Notice] Skipping inner class: #{class_name exp[1]}"
      return ignore
    end

    name = class_name(exp[1])
    if @current_module
      name = (@current_module + "::" + name.to_s).to_sym
    end
    @controller = { :name => name,
                    :parent => class_name(exp[2]),
                    :includes => [],
                    :public => {},
                    :private => {},
                    :protected => {},
                    :options => {},
                    :src => exp,
                    :file => @file_name }
    @tracker.controllers[@controller[:name]] = @controller
    exp[3] = process exp[3]
    set_layout_name
    @controller = nil
    exp
  end

  #Look for specific calls inside the controller
  def process_call exp
    target = exp[1]
    if sexp? target
      target = process target
    end

    method = exp[2]
    args = exp[3]

    #Methods called inside class definition
    #like attr_* and other settings
    if @current_method.nil? and target.nil? and @controller
      if args.length == 1 #actually, empty
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
          @controller[:includes] << class_name(args[1]) if @controller
        when :before_filter
          @controller[:options][:before_filters] ||= []
          @controller[:options][:before_filters] << args[1..-1]
        when :layout
          if string? args[-1]
            #layout "some_layout"

            name = args[-1][1].to_s
            unless Dir.glob("#{@tracker.options[:app_path]}/app/views/layouts/#{name}.html.{erb,haml}").empty?
              @controller[:layout] = "layouts/#{name}"
            else
              Brakeman.debug "[Notice] Layout not found: #{name}"
            end
          elsif sexp? args[-1] and (args[-1][0] == :nil or args[-1][0] == :false)
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
      call = Sexp.new :call, target, method, process(args)
      call.line(exp.line)
      call
    end
  end

  #Process method definition and store in Tracker
  def process_defn exp
    name = exp[1]
    @current_method = name
    res = Sexp.new :methdef, name, process(exp[2]), process(exp[3][1])
    res.line(exp.line)
    @current_method = nil
    @controller[@visibility][name] = res unless @controller.nil?

    res
  end

  #Process self.method definition and store in Tracker
  def process_defs exp
    name = exp[2]

    if exp[1].node_type == :self
      target = @controller[:name]
    else
      target = class_name exp[1]
    end

    @current_method = name
    res = Sexp.new :selfdef, target, name, process(exp[3]), process(exp[4][1])
    res.line(exp.line)
    @current_method = nil
    @controller[@visibility][name] = res unless @controller.nil?

    res
  end

  #Look for before_filters and add fake ones if necessary
  def process_iter exp
    if exp[1][2] == :before_filter
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
    args = exp[1][3]
    args.insert(1, Sexp.new(:lit, filter_name))
    before_filter_call = Sexp.new(:call, nil, :before_filter, args)

    if exp[2]
      block_variable = exp[2][1]
    else
      block_variable = :temp
    end

    if sexp? exp[3] and exp[3].node_type == :block
      block_inner = exp[3][1..-1]
    else
      block_inner = [exp[3]]
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
