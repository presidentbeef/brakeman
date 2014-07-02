require 'brakeman/processors/base_processor'

#Processes models. Puts results in tracker.models
class Brakeman::ModelProcessor < Brakeman::BaseProcessor

  ASSOCIATIONS = Set[:belongs_to, :has_one, :has_many, :has_and_belongs_to_many]

  def initialize tracker
    super
    @current_class = nil
    @current_method = nil
    @current_module = nil
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
    name = class_name(exp.class_name)
    parent = class_name(exp.parent_name)

    #If inside an inner class we treat it as a library.
    if @current_class
      Brakeman.debug "[Notice] Treating inner class as library: #{name}"
      Brakeman::LibraryProcessor.new(@tracker).process_library exp, @file_name
      return exp
    end

    if @current_class
      outer_class = @current_class
      name = (outer_class[:name].to_s + "::" + name.to_s).to_sym
    end

    if @current_module
      name = (@current_module[:name].to_s + "::" + name.to_s).to_sym
    end

    if @tracker.models[name]
      @current_class = @tracker.models[name]
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
        :options => {},
        :src => { @file_name => exp },
        :associations => {},
        :files => [ @file_name ]
      }

      @tracker.models[name] = @current_class
    end

    exp.body = process_all! exp.body

    if outer_class
      @current_class = outer_class
    else
      @current_class = nil
    end

    exp
  end

  def process_module exp
    name = class_name(exp.class_name)

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
        :includes => [],
        :public => {},
        :private => {},
        :protected => {},
        :options => {},
        :src => { @file_name => exp },
        :associations => {},
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

  #Handle calls outside of methods,
  #such as include, attr_accessible, private, etc.
  def process_call exp
    return exp unless @current_class
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
          @current_class[:attr_accessible] ||= []
        else
          #??
        end
      else
        case method
        when :include
          @current_class[:includes] << class_name(first_arg) if @current_class
        when :attr_accessible
          @current_class[:attr_accessible] ||= []
          args = []

          exp.each_arg do |e|
            if node_type? e, :lit
              args << e.value
            elsif hash? e
              @current_class[:options][:role_accessible] ||= []
              @current_class[:options][:role_accessible].concat args
            end
          end

          @current_class[:attr_accessible].concat args
        else
          if @current_class
            if ASSOCIATIONS.include? method
              @current_class[:associations][method] ||= []
              @current_class[:associations][method].concat exp.args
            else
              @current_class[:options][method] ||= []
              @current_class[:options][method] << exp.arglist.line(exp.line)
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
    return exp unless @current_class
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

  #Add method definition to tracker
  def process_defs exp
    return exp unless @current_class
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

end
