require 'brakeman/processors/base_processor'
require 'brakeman/processors/lib/module_helper'
require 'brakeman/tracker/model'

#Processes models. Puts results in tracker.models
class Brakeman::ModelProcessor < Brakeman::BaseProcessor
  include Brakeman::ModuleHelper

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

    handle_class exp, @tracker.models, Brakeman::Model
  end

  def process_module exp
    handle_module exp, Brakeman::Model
  end

  #Handle calls outside of methods,
  #such as include, attr_accessible, private, etc.
  def process_call exp
    return exp unless @current_class
    return exp if process_call_defn? exp

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
          @current_class.set_attr_accessible
        else
          #??
        end
      else
        case method
        when :include
          @current_class.add_include class_name(first_arg) if @current_class
        when :attr_accessible
          @current_class.set_attr_accessible exp
        when :attr_protected
          @current_class.set_attr_protected exp
        else
          if @current_class
            @current_class.add_option method, exp
          end
        end
      end

      exp
    else
      call = make_call target, method, process_all!(exp.args)
      call.line(exp.line)
      call
    end
  end
end
