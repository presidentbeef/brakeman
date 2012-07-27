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
    name = class_name exp.class_name

    if @model
      Brakeman.debug "[Notice] Skipping inner class: #{name}"
      ignore
    else
      @model = { :name => name,
        :parent => class_name(exp.parent_name),
        :includes => [],
        :public => {},
        :private => {},
        :protected => {},
        :options => {},
        :file => @file_name }
      @tracker.models[@model[:name]] = @model
      res = process exp.body
      @model = nil
      res
    end
  end

  #Handle calls outside of methods,
  #such as include, attr_accessible, private, etc.
  def process_call exp
    return exp unless @model
    target = exp.target
    if sexp? target
      target = process target
    end

    method = exp.method
    args = exp.args

    #Methods called inside class definition
    #like attr_* and other settings
    if @current_method.nil? and target.nil?
      if args.empty?
        case method
        when :private, :protected, :public
          @visibility = method
        when :attr_accessible
          @model[:attr_accessible] ||= []
        else
          #??
        end
      else
        case method
        when :include
          @model[:includes] << class_name(args.first) if @model
        when :attr_accessible
          @model[:attr_accessible] ||= []
          args = args.map do |e|
            e[1]
          end

          @model[:attr_accessible].concat args
        else
          if @model
            @model[:options][method] ||= []
            @model[:options][method] << exp.arglist
          end
        end
      end
      ignore
    else
      call = Sexp.new :call, target, method, process(exp.arglist)
      call.line(exp.line)
      call
    end
  end

  #Add method definition to tracker
  def process_defn exp
    return exp unless @model
    name = exp.meth_name

    @current_method = name
    res = Sexp.new :methdef, name, exp[2], process(exp.body.value)
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
    name = exp.meth_name

    if exp[1].node_type == :self
      target = @model[:name]
    else
      target = class_name exp[1]
    end

    @current_method = name
    res = Sexp.new :selfdef, target, name, exp[3], process(exp.body.value)
    res.line(exp.line)
    @current_method = nil
    if @model
      @model[@visibility][name] = res unless @model.nil?
    end
    res
  end

end
