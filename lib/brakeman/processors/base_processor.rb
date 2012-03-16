require 'rubygems'
require 'sexp_processor'
require 'brakeman/processors/lib/processor_helper'
require 'brakeman/util'

#Base processor for most processors.
class Brakeman::BaseProcessor < SexpProcessor
  include Brakeman::ProcessorHelper
  include Brakeman::Util

  attr_reader :ignore

  #Return a new Processor.
  def initialize tracker
    super()
    self.strict = false
    self.auto_shift_type = false
    self.require_empty = false
    self.default_method = :process_default
    self.warn_on_default = false
    @last = nil
    @tracker = tracker
    @ignore = Sexp.new :ignore
    @current_template = @current_module = @current_class = @current_method = nil
  end

  def process_class exp
    current_class = @current_class
    @current_class = class_name exp[1]
    process exp[3]
    @current_class = current_class
    exp
  end

  def process_module exp
    current_module = @current_module
    @current_module = class_name exp[1]
    process exp[2]
    @current_module = current_module
    exp
  end

  #Process a new scope. Removes expressions that are set to nil.
  def process_scope exp
    exp = exp.dup
    exp.shift
    exp.map! do |e|
      res = process e
      if res.empty?
        res = nil
      else
        res
      end
    end.compact
    exp.unshift :scope
  end

  #Default processing.
  def process_default exp
    exp = exp.dup
    type = exp.shift
    exp.each_with_index do |e, i|
      if sexp? e and not e.empty?
        exp[i] = process e
      else
        e
      end
    end
  ensure
    exp.unshift type
  end

  #Process an if statement.
  def process_if exp
    exp = exp.dup
    exp[1] = process exp[1]
    exp[2] = process exp[2] if exp[2]
    exp[3] = process exp[3] if exp[3]
    exp
  end

  #Processes calls with blocks. Changes Sexp node type to :call_with_block
  #
  #s(:iter, CALL, {:lasgn|:masgn}, BLOCK)
  def process_iter exp
    exp = exp.dup
    call = process exp[1]
    #deal with assignments somehow
    if exp[3]
      block = process exp[3]
      block = nil if block.empty?
    else
      block = nil
    end

    call = Sexp.new(:call_with_block, call, exp[2], block).compact
    call.line(exp.line)
    call
  end

  #String with interpolation. Changes Sexp node type to :string_interp
  def process_dstr exp
    exp = exp.dup
    exp.shift
    exp.map! do |e|
      if e.is_a? String
        e
      elsif e[1].is_a? String
        e[1]
      else
        res = process e
        if res.empty?
          nil
        else
          res
        end
      end
    end.compact!

    exp.unshift :string_interp
  end

  #Processes a block. Changes Sexp node type to :rlist
  def process_block exp
    exp = exp.dup
    exp.shift

    exp.map! do |e|
      process e
    end

    exp.unshift :rlist
  end

  #Processes the inside of an interpolated String.
  #Changes Sexp node type to :string_eval
  def process_evstr exp
    exp = exp.dup
    exp[0] = :string_eval
    exp[1] = process exp[1]
    exp
  end

  #Processes an or keyword
  def process_or exp
    exp = exp.dup
    exp[1] = process exp[1]
    exp[2] = process exp[2]
    exp
  end

  #Processes an and keyword
  def process_and exp
    exp = exp.dup
    exp[1] = process exp[1]
    exp[2] = process exp[2]
    exp
  end

  #Processes a hash
  def process_hash exp
    exp = exp.dup
    exp.shift
    exp.map! do |e|
      if sexp? e
        process e
      else
        e
      end
    end

    exp.unshift :hash
  end

  #Processes the values in an argument list
  def process_arglist exp
    exp = exp.dup
    exp.shift
    exp.map! do |e|
      process e
    end

    exp.unshift :arglist
  end

  #Processes a local assignment
  def process_lasgn exp
    exp = exp.dup
    exp[2] = process exp[2]
    exp
  end

  #Processes an instance variable assignment
  def process_iasgn exp
    exp = exp.dup
    exp[2] = process exp[2]
    exp
  end

  #Processes an attribute assignment, which can be either x.y = 1 or x[:y] = 1
  def process_attrasgn exp
    exp = exp.dup
    exp[1] = process exp[1]
    exp[3] = process exp[3]
    exp
  end

  #Ignore ignore Sexps
  def process_ignore exp
    exp
  end

  #Convenience method for `make_render exp, true`
  def make_render_in_view exp
    make_render exp, true
  end

  #Generates :render node from call to render.
  def make_render exp, in_view = false 
    render_type, value, rest = find_render_type exp[3], in_view
    rest = process rest
    result = Sexp.new(:render, render_type, value, rest)
    result.line(exp.line)
    result
  end

  #Determines the type of a call to render.
  #
  #Possible types are:
  #:action, :default, :file, :inline, :js, :json, :nothing, :partial,
  #:template, :text, :update, :xml
  #
  #And also :layout for inside templates
  def find_render_type args, in_view = false
    rest = Sexp.new(:hash)
    type = nil
    value = nil

    if args.length == 2 and args[-1] == Sexp.new(:lit, :update)
      return :update, nil, args[0..-2]
    end

    #Look for render :action, ... or render "action", ...
    if string? args[1] or symbol? args[1]
      if @current_template and @tracker.options[:rails3]
        type = :partial
        value = args[1]
      else
        type = :action
        value = args[1]
      end
    elsif args[1].is_a? Symbol or args[1].is_a? String
      type = :action
      value = Sexp.new(:lit, args[1].to_sym)
		elsif args[1].nil?
			type = :default
    elsif not hash? args[1]
      type = :action
      value = args[1]
    end

    types_in_hash = Set[:action, :file, :inline, :js, :json, :nothing, :partial, :text, :update, :xml]

    #render :layout => "blah" means something else when in a template
    if in_view
      types_in_hash << :layout
    end

    #Look for "type" of render in options hash
    #For example, render :file => "blah"
    if hash? args[-1]
      hash_iterate(args[-1]) do |key, val|
        if types_in_hash.include? key[1]
          type = key[1]
          value = val
        else  
          rest << key << val
        end
      end
    end

    type ||= :default
    value ||= :default
    args[-1] = rest
    return type, value, rest
  end
end
