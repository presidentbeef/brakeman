require 'brakeman/processors/base_processor'

#Processes models. Puts results in tracker.models
class Brakeman::ModelProcessor < Brakeman::BaseProcessor
  def initialize tracker
    super 
    @model = nil
    @current_method = nil
    @visibility = :public
    @file_name = nil
  end

  #Process model source
  def process_model src, file_name = nil
    @file_name = file_name
    process src
  end

  #s(:class, NAME, PARENT, s(:scope ...))
  def process_class exp
    if @model
      warn "[Notice] Skipping inner class: #{class_name exp[1]}" if @tracker.options[:debug]
      ignore
    else
      @model = { :name => class_name(exp[1]),
        :parent => class_name(exp[2]),
        :includes => [],
        :public => {},
        :private => {},
        :protected => {},
        :options => {},
        :file => @file_name }
      @tracker.models[@model[:name]] = @model
      res = process exp[3]
      @model = nil
      res
    end
  end

  #Handle calls outside of methods,
  #such as include, attr_accessible, private, etc.
  def process_call exp
    return exp unless @model
    target = exp[1]
    if sexp? target
      target = process target
    end

    method = exp[2]
    args = exp[3]

    #Methods called inside class definition
    #like attr_* and other settings
    if @current_method.nil? and target.nil?
      if args.length == 1 #actually, empty
        case method
        when :private, :protected, :public
          @visibility = method
        else
          #??
        end
      else
        case method
        when :include
          @model[:includes] << class_name(args[1]) if @model
        when :attr_accessible
          @model[:attr_accessible] ||= []
          args = args[1..-1].map do |e|
            e[1]
          end

          @model[:attr_accessible].concat args
        else
          if @model
            @model[:options][method] ||= []
            @model[:options][method] << args
          end
        end
      end
      ignore
    else
      call = Sexp.new :call, target, method, process(args)
      call.line(exp.line)
      call
    end
  end

  #Add method definition to tracker
  def process_defn exp
    return exp unless @model
    name = exp[1]

    @current_method = name
    res = Sexp.new :methdef, name, process(exp[2]), process(exp[3][1])
    res.line(exp.line)
    @current_method = nil
    if @model
      list = @model[@visibility]
      list[name] = res
    end
    res
  end

  #Add method definition to tracker
  def process_defs exp
    return exp unless @model
    name = exp[2]

    if exp[1].node_type == :self
      target = @model[:name]
    else
      target = class_name exp[1]
    end

    @current_method = name
    res = Sexp.new :selfdef, target, name, process(exp[3]), process(exp[4][1])
    res.line(exp.line)
    @current_method = nil
    if @model
      @model[@visibility][name] = res unless @model.nil?
    end
    res
  end

end
