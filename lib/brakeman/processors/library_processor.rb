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
    name = class_name(exp[1])
    
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
      @current_class = { :name => name,
                    :parent => class_name(exp[2]),
                    :includes => [],
                    :public => {},
                    :private => {},
                    :protected => {},
                    :src => exp,
                    :file => @file_name }
    
      @tracker.libs[name] = @current_class
    end

    exp[3] = process exp[3]

    if outer_class
      @current_class = outer_class
    else
      @current_class = nil
    end

    exp
  end

  def process_module exp
    name = class_name(exp[1])

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

    exp[2] = process exp[2]

    if outer_class
      @current_module = outer_class
    else
      @current_module = nil
    end

    exp
  end

  def process_defn exp
    exp[0] = :methdef
    exp[3] = @alias_processor.process exp[3]

    if @current_class
      @current_class[:public][exp[1]] = exp[3]
    elsif @current_module
      @current_module[:public][exp[1]] = exp[3]
    end

    exp
  end

  def process_defs exp
    exp[0] = :selfdef
    exp[4] = @alias_processor.process exp[4]

    if @current_class
      @current_class[:public][exp[2]] = exp[4]
    elsif @current_module
      @current_module[:public][exp[3]] = exp[4]
    end

    exp
  end
end
