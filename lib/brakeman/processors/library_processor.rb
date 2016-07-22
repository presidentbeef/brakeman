require 'brakeman/processors/base_processor'
require 'brakeman/processors/alias_processor'
require 'brakeman/processors/lib/module_helper'
require 'brakeman/tracker/library'

#Process generic library and stores it in Tracker.libs
class Brakeman::LibraryProcessor < Brakeman::BaseProcessor
  include Brakeman::ModuleHelper

  def initialize tracker
    super
    @file_name = nil
    @alias_processor = Brakeman::AliasProcessor.new tracker
    @current_module = nil
    @current_class = nil
  end

  def process_library src, file_name = nil
    @file_name = file_name
    process src
  end

  def process_class exp
    handle_class exp, @tracker.libs, Brakeman::Library
  end

  def process_module exp
    handle_module exp, Brakeman::Library
  end

  def process_defn exp
    exp = @alias_processor.process exp

    if @current_class
      exp.body = process_all! exp.body
      @current_class.add_method :public, exp.method_name, exp, @file_name
    elsif @current_module
      exp.body = process_all! exp.body
      @current_module.add_method :public, exp.method_name, exp, @file_name
    end

    exp
  end

  alias process_defs process_defn

  def process_call exp
    if process_call_defn? exp
      exp
    else
      process_default exp
    end
  end
end
