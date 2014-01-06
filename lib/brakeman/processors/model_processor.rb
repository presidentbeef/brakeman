require 'brakeman/processors/base_processor'

#Processes models. Puts results in tracker.models
class Brakeman::ModelProcessor < Brakeman::BaseProcessor

  ASSOCIATIONS = Set[:belongs_to, :has_one, :has_many, :has_and_belongs_to_many]

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

  #s(:class, NAME, PARENT, BODY)
  def process_class exp
    name = class_name exp.class_name

    if @model
      Brakeman.debug "[Notice] Skipping inner class: #{name}"
      ignore
    else
      parent = class_name exp.parent_name

      @model = { :name => name,
        :parent => parent,
        :includes => [],
        :public => {},
        :private => {},
        :protected => {},
        :options => {},
        :associations => {},
        :file => @file_name }
      @tracker.models[@model[:name]] = @model
      exp.body = process_all! exp.body
      @model = nil
      exp
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
    first_arg = exp.first_arg

    #Methods called inside class definition
    #like attr_* and other settings
    if @current_method.nil? and target.nil?
      if first_arg.nil?
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
          @model[:includes] << class_name(first_arg) if @model
        when :attr_accessible
          @model[:attr_accessible] ||= []
          args = []

          exp.each_arg do |e|
            if node_type? e, :lit
              args << e.value
            elsif hash? e
              @model[:options][:role_accessible] ||= []
              @model[:options][:role_accessible].concat args
            end
          end

          @model[:attr_accessible].concat args
        else
          if @model
            if ASSOCIATIONS.include? method
              @model[:associations][method] ||= []
              @model[:associations][method].concat exp.args
            else
              @model[:options][method] ||= []
              @model[:options][method] << exp.arglist.line(exp.line)
            end
          end
        end
      end
      ignore
    else
      call = make_call target, method, process_all!(exp.args)
      call.line(exp.line)
      call
    end
  end

  #Add method definition to tracker
  def process_defn exp
    return exp unless @model
    name = exp.method_name

    @current_method = name
    res = Sexp.new :methdef, name, exp.formal_args, *process_all!(exp.body)
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
    name = exp.method_name

    if exp[1].node_type == :self
      target = @model[:name]
    else
      target = class_name exp[1]
    end

    @current_method = name
    res = Sexp.new :selfdef, target, name, exp.formal_args, *process_all!(exp.body)
    res.line(exp.line)
    @current_method = nil
    if @model
      @model[@visibility][name] = res unless @model.nil?
    end
    res
  end

end
