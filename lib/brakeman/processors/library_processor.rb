require 'brakeman/processors/base_processor'
require 'brakeman/processors/alias_processor'

#Process generic library and stores it in Tracker.libs
class Brakeman::LibraryProcessor < Brakeman::BaseProcessor

  def initialize tracker
    super
    @file_name = nil
    @alias_processor = Brakeman::AliasProcessor.new tracker
  end

  def process_library src, file_name = nil
    @file_name = file_name
    process src
  end

  def process_class exp
    name = class_name(exp.class_name)
    
    if @current_class
      outer_class = @current_class
      name = (outer_class[:name].to_s + "::" + name.to_s).to_sym
    end

    if @current_module
      name = (@current_module[:name].to_s + "::" + name.to_s).to_sym
    end

    if @tracker.libs[name]
      @current_class = @tracker.libs[name]
    else
      parent = class_name exp.parent_name

      @current_class = { :name => name,
                    :parent => parent,
                    :includes => [],
                    :public => {},
                    :private => {},
                    :protected => {},
                    :src => exp,
                    :file => @file_name }
    
      @tracker.libs[name] = @current_class
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
    name = class_name(exp.module_name)

    if @current_module
      outer_class = @current_module
      name = (outer_class[:name].to_s + "::" + name.to_s).to_sym
    end

    if @current_class
      name = (@current_class[:name].to_s + "::" + name.to_s).to_sym
    end

    if @tracker.libs[name]
      @current_module = @tracker.libs[name]
    else
      @current_module = { :name => name,
                    :includes => [],
                    :public => {},
                    :private => {},
                    :protected => {},
                    :src => exp,
                    :file => @file_name }
    
      @tracker.libs[name] = @current_module
    end

    exp.body = process_all! exp.body

    if outer_class
      @current_module = outer_class
    else
      @current_module = nil
    end

    exp
  end

  def process_defn exp
    exp = @alias_processor.process exp
    exp.node_type = :methdef

    if @current_class
      @current_class[:public][exp.method_name] = exp
    elsif @current_module
      @current_module[:public][exp.method_name] = exp
    end

    exp
  end

  def process_defs exp
    exp = @alias_processor.process exp
    exp.node_type = :selfdef

    if @current_class
      @current_class[:public][exp.method_name] = exp
    elsif @current_module
      @current_module[:public][exp.method_name] = exp
    end

    exp
  end
end
