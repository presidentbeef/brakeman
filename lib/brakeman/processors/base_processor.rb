require 'brakeman/processors/lib/processor_helper'
require 'brakeman/util'

#Base processor for most processors.
class Brakeman::BaseProcessor < Brakeman::SexpProcessor
  include Brakeman::ProcessorHelper
  include Brakeman::Util

  IGNORE = Sexp.new :ignore

  #Return a new Processor.
  def initialize tracker
    super()
    @last = nil
    @tracker = tracker
    @current_template = @current_module = @current_class = @current_method = nil
  end

  def ignore
    IGNORE
  end

  def process_class exp
    current_class = @current_class
    @current_class = class_name exp[1]
    process_all exp.body
    @current_class = current_class
    exp
  end

  #Process a new scope. Removes expressions that are set to nil.
  def process_scope exp
    #NOPE?
  end

  #Default processing.
  def process_default exp
    exp = exp.dup

    exp.each_with_index do |e, i|
      if sexp? e and not e.empty?
        exp[i] = process e
      else
        e
      end
    end

    exp
  end

  #Process an if statement.
  def process_if exp
    exp = exp.dup
    exp[1] = process exp.condition
    exp[2] = process exp.then_clause if exp.then_clause
    exp[3] = process exp.else_clause if exp.else_clause
    exp
  end

  #Processes calls with blocks. Changes Sexp node type to :call_with_block
  #
  #s(:iter, CALL, {:lasgn|:masgn}, BLOCK)
  def process_iter exp
    exp = exp.dup
    call = process exp.block_call
    #deal with assignments somehow
    if exp.block
      block = process exp.block
      block = nil if block.empty?
    else
      block = nil
    end

    call = Sexp.new(:call_with_block, call, exp.block_args, block).compact
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
      elsif e.value.is_a? String
        e.value
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
    exp.rhs = process exp.rhs
    exp
  end

  alias :process_iasgn :process_lasgn

  #Processes an instance variable assignment
  def process_iasgn exp
    exp = exp.dup
    exp.rhs = process exp.rhs
    exp
  end

  #Processes an attribute assignment, which can be either x.y = 1 or x[:y] = 1
  def process_attrasgn exp
    exp = exp.dup
    exp.target = process exp.target
    exp.arglist = process exp.arglist
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
    render_type, value, rest = find_render_type exp, in_view
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
  def find_render_type call, in_view = false
    rest = Sexp.new(:hash)
    type = nil
    value = nil
    first_arg = call.first_arg

    if call.second_arg.nil? and first_arg == Sexp.new(:lit, :update)
      return :update, nil, Sexp.new(:arglist, *call.args[0..-2]) #TODO HUH?
    end

    #Look for render :action, ... or render "action", ...
    if string? first_arg or symbol? first_arg
      if @current_template and @tracker.options[:rails3]
        type = :partial
        value = first_arg
      else
        type = :action
        value = first_arg
      end
    elsif first_arg.is_a? Symbol or first_arg.is_a? String
      type = :action
      value = Sexp.new(:lit, first_arg.to_sym)
		elsif first_arg.nil?
			type = :default
    elsif not hash? first_arg
      type = :action
      value = first_arg
    end

    types_in_hash = Set[:action, :file, :inline, :js, :json, :nothing, :partial, :template, :text, :update, :xml]

    #render :layout => "blah" means something else when in a template
    if in_view
      types_in_hash << :layout
    end

    last_arg = call.last_arg

    #Look for "type" of render in options hash
    #For example, render :file => "blah"
    if hash? last_arg
      hash_iterate(last_arg) do |key, val|
        if symbol? key and types_in_hash.include? key.value
          type = key.value
          value = val
        else  
          rest << key << val
        end
      end
    end

    type ||= :default
    value ||= :default
    return type, value, rest
  end
end
