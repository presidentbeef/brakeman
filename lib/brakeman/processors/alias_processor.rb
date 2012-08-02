require 'brakeman/util'
require 'ruby_parser/bm_sexp_processor'
require 'brakeman/processors/lib/processor_helper'

#Returns an s-expression with aliases replaced with their value.
#This does not preserve semantics (due to side effects, etc.), but it makes
#processing easier when searching for various things.
class Brakeman::AliasProcessor < Brakeman::SexpProcessor
  include Brakeman::ProcessorHelper
  include Brakeman::Util

  attr_reader :result

  #Returns a new AliasProcessor with an empty environment.
  #
  #The recommended usage is:
  #
  # AliasProcessor.new.process_safely src
  def initialize tracker = nil
    super()
    @env = SexpProcessor::Environment.new
    @inside_if = false
    @ignore_ifs = false
    @exp_context = []
    @current_module = nil
    @tracker = tracker #set in subclass as necessary
    set_env_defaults
  end

  #This method processes the given Sexp, but copies it first so
  #the original argument will not be modified.
  #
  #_set_env_ should be an instance of SexpProcessor::Environment. If provided,
  #it will be used as the starting environment.
  #
  #This method returns a new Sexp with variables replaced with their values,
  #where possible.
  def process_safely src, set_env = nil
    @env = Marshal.load(Marshal.dump(set_env)) if set_env
    @result = src.deep_clone
    process @result

    #Process again to propogate replaced variables and process more.
    #For example,
    #  x = [1,2]
    #  y = [3,4]
    #  z = x + y
    #
    #After first pass:
    #
    #  z = [1,2] + [3,4]
    #
    #After second pass:
    #
    #  z = [1,2,3,4]
    if set_env
      @env = set_env
    else
      @env = SexpProcessor::Environment.new
    end

    process @result

    @result
  end

  #Process a Sexp. If the Sexp has a value associated with it in the
  #environment, that value will be returned. 
  def process_default exp
    @exp_context.push exp

    begin
      exp.each_with_index do |e, i|
        next if i == 0

        if sexp? e and not e.empty?
          exp[i] = process e
        else
          e
        end
      end
    rescue Exception => err
      @tracker.error err if @tracker
    end

    #Generic replace
    if replacement = env[exp] and not duplicate? replacement
      result = set_line replacement.deep_clone, exp.line
    else
      result = exp
    end

    @exp_context.pop

    result
  end

  #Process a method call.
  def process_call exp
    target_var = exp.target
    exp = process_default exp

    #In case it is replaced with something else
    unless call? exp
      return exp
    end

    target = exp.target
    method = exp.method
    args = exp[3]
    first_arg = exp.first_arg

    #See if it is possible to simplify some basic cases
    #of addition/concatenation.
    case method
    when :+
      if array? target and array? first_arg
        joined = join_arrays target, first_arg 
        joined.line(exp.line)
        exp = joined
      elsif string? first_arg
        if string? target # "blah" + "blah"
          joined = join_strings target, first_arg
          joined.line(exp.line)
          exp = joined
        elsif call? target and target.method == :+ and string? target.first_arg
          joined = join_strings target.first_arg, first_arg
          joined.line(exp.line)
          target.first_arg = joined
          exp = target
        end
      elsif number? first_arg
        if number? target
          exp = Sexp.new(:lit, target.value + first_arg.value)
        elsif call? target and target.method == :+ and number? target.first_arg
          target.first_arg = Sexp.new(:lit, target.first_arg + first_arg.value)
          exp = target
        end
      end
    when :-
      if number? target and number? first_arg
        exp = Sexp.new(:lit, target.value - first_arg.value)
      end
    when :*
      if number? target and number? first_arg
        exp = Sexp.new(:lit, target.value * first_arg.value)
      end
    when :/
      if number? target and number? first_arg
        exp = Sexp.new(:lit, target.value / first_arg.value)
      end
    when :[]
      if array? target
        temp_exp = process_array_access target, exp.args
        exp = temp_exp if temp_exp
      elsif hash? target
        temp_exp = process_hash_access target, exp.args
        exp = temp_exp if temp_exp
      end
    when :merge!, :update
      if hash? target and hash? first_arg
         target = process_hash_merge! target, first_arg
         env[target_var] = target
         return target
      end
    when :merge
      if hash? target and hash? first_arg
        return process_hash_merge(target, first_arg)
      end
    when :<<
      if string? target and string? first_arg
        target.value << first_arg.value
        env[target_var] = target
        return target
      elsif array? target
        target << first_arg
        env[target_var] = target
        return target
      else
        target = find_push_target exp
        env[target] = exp unless target.nil? #Happens in TemplateAliasProcessor
      end
    end

    exp
  end

  #Process a new scope.
  def process_scope exp
    env.scope do
      process exp.block
    end
    exp
  end

  #Start new scope for block.
  def process_block exp
    env.scope do
      process_default exp
    end
  end

  #Process a method definition.
  def process_methdef exp
    env.scope do
      set_env_defaults
      process exp.body
    end
    exp
  end

  #Process a method definition on self.
  def process_selfdef exp
    env.scope do
      set_env_defaults
      process exp.body
    end
    exp
  end

  alias process_defn process_methdef
  alias process_defs process_selfdef

  #Local assignment
  # x = 1
  def process_lasgn exp
    exp.rhs = process exp.rhs if sexp? exp.rhs
    return exp if exp.rhs.nil?

    local = Sexp.new(:lvar, exp.lhs).line(exp.line || -2)

    if @inside_if and val = env[local]
      #avoid setting to value it already is (e.g. "1 or 1")
      if val != exp.rhs and val[1] != exp.rhs and val[2] != exp.rhs
        env[local] = Sexp.new(:or, val, exp.rhs).line(exp.line || -2)
      end
    else
      env[local] = exp.rhs
    end

    exp
  end

  #Instance variable assignment
  # @x = 1
  def process_iasgn exp
    exp.rhs = process exp.rhs
    ivar = Sexp.new(:ivar, exp.lhs).line(exp.line)

    if @inside_if and val = env[ivar]
      if val != exp.rhs
        env[ivar] = Sexp.new(:or, val, exp.rhs).line(exp.line)
      end
    else
      env[ivar] = exp.rhs
    end

    exp
  end

  #Global assignment
  # $x = 1
  def process_gasgn exp
    match = Sexp.new(:gvar, exp.lhs)
    value = exp.rhs = process(exp.rhs)

    if @inside_if and val = env[match]
      if val != value
        env[match] = Sexp.new(:or, env[match], value)
      end
    else
      env[match] = value
    end

    exp
  end

  #Class variable assignment
  # @@x = 1
  def process_cvdecl exp
    match = Sexp.new(:cvar, exp.lhs)
    value = exp.rhs = process(exp.rhs)
    
    if @inside_if and val = env[match]
      if val != value
        env[match] = Sexp.new(:or, env[match], value)
      end
    else
      env[match] = value
    end

    exp
  end

  #'Attribute' assignment
  # x.y = 1
  #or
  # x[:y] = 1
  def process_attrasgn exp
    tar_variable = exp.target
    target = exp.target = process(exp.target)
    method = exp.method
    args = exp.args

    if method == :[]=
      index = exp.first_arg = process(args.first)
      value = exp.second_arg = process(args.second)
      match = Sexp.new(:call, target, :[], Sexp.new(:arglist, index))
      env[match] = value

      if hash? target
        env[tar_variable] = hash_insert target.deep_clone, index, value
      end
    elsif method.to_s[-1,1] == "="
      value = exp.first_arg = process(args.first)
      #This is what we'll replace with the value
      match = Sexp.new(:call, target, method.to_s[0..-2].to_sym, Sexp.new(:arglist))

      if @inside_if and val = env[match]
        if val != value
          env[match] = Sexp.new(:or, env[match], value)
        end
      else
        env[match] = value
      end
    else
      raise "Unrecognized assignment: #{exp}"
    end
    exp
  end

  #Merge values into hash when processing
  #
  # h.merge! :something => "value"
  def process_hash_merge! hash, args
    hash = hash.deep_clone
    hash_iterate args do |key, replacement|
      hash_insert hash, key, replacement
      match = Sexp.new(:call, hash, :[], Sexp.new(:arglist, key))
      env[match] = replacement
    end
    hash
  end

  #Return a new hash Sexp with the given values merged into it.
  #
  #+args+ should be a hash Sexp as well.
  def process_hash_merge hash, args
    hash = hash.deep_clone
    hash_iterate args do |key, replacement|
      hash_insert hash, key, replacement
    end
    hash
  end

  #Assignments like this
  # x[:y] ||= 1
  def process_op_asgn1 exp
    return process_default(exp) if exp[3] != :"||"

    target = exp[1] = process(exp[1])
    index = exp[2][1] = process(exp[2][1])
    value = exp[4] = process(exp[4])
    match = Sexp.new(:call, target, :[], Sexp.new(:arglist, index))

    unless env[match]
      if request_value? target
        env[match] = Sexp.new(:or, match, value)
      else
        env[match] = value
      end
    end

    exp
  end

  #Assignments like this
  # x.y ||= 1
  def process_op_asgn2 exp
    return process_default(exp) if exp[3] != :"||"

    target = exp[1] = process(exp[1])
    value = exp[4] = process(exp[4])
    method = exp[2]

    match = Sexp.new(:call, target, method.to_s[0..-2].to_sym, Sexp.new(:arglist))

    unless env[match]
      env[match] = value
    end

    exp
  end

  def process_svalue exp
    exp[1]
  end

  #Constant assignments like
  # BIG_CONSTANT = 234810983
  def process_cdecl exp
    if sexp? exp.rhs
      exp.rhs = process exp.rhs
    end

    if exp.lhs.is_a? Symbol
      match = Sexp.new(:const, exp.lhs)
    else
      match = exp.lhs
    end

    env[match] = exp.rhs

    exp
  end

  #Sets @inside_if = true
  def process_if exp
    @ignore_ifs ||= @tracker && @tracker.options[:ignore_ifs]

    condition = process exp.condition

    if true? condition
      exps = [exp.then_clause]
    elsif false? condition
      exps = exp[3..-1]
    else
      exps = exp[2..-1]
    end

    was_inside = @inside_if
    @inside_if = !@ignore_ifs

    exps.each do |e|
      if sexp? e
        if e.node_type == :block
          process_default e #avoid creating new scope
        else
          process e
        end
      end
    end

    @inside_if = was_inside

    exp
  end

  #Process single integer access to an array. 
  #
  #Returns the value inside the array, if possible.
  def process_array_access target, args
    if args.length == 1 and integer? args[0]
      index = args[0][1]

      #Have to do this because first element is :array and we have to skip it
      target[1..-1][index + 1]
    else
      nil
    end
  end

  #Process hash access by returning the value associated
  #with the given arguments.
  def process_hash_access target, args
    if args.length == 1
      index = args[0]

      hash_access(target, index)
    else
      nil
    end
  end

  #Join two array literals into one.
  def join_arrays array1, array2
    result = Sexp.new(:array)
    result.concat array1[1..-1]
    result.concat array2[1..-1]
  end

  #Join two string literals into one.
  def join_strings string1, string2
    result = Sexp.new(:str)
    result[1] = string1[1] + string2[1]
    if result[1].length > 50
      string1
    else
      result
    end
  end

  #Returns a new SexpProcessor::Environment containing only instance variables.
  #This is useful, for example, when processing views.
  def only_ivars include_request_vars = false
    res = SexpProcessor::Environment.new

    if include_request_vars
      env.all.each do |k, v|
        #TODO Why would this have nil values?
        if (k.node_type == :ivar or request_value? k) and not v.nil?
          res[k] = v.dup
        end
      end
    else
      env.all.each do |k, v|
        #TODO Why would this have nil values?
        if k.node_type == :ivar and not v.nil?
          res[k] = v.dup
        end
      end
    end

    res
  end

  #Set line nunber for +exp+ and every Sexp it contains. Used when replacing
  #expressions, so warnings indicate the correct line.
  def set_line exp, line_number
    if sexp? exp
      exp.original_line(exp.original_line || exp.line)
      exp.line line_number
      exp.each do |e|
        set_line e, line_number
      end
    end

    exp
  end

  #Finds the inner most call target which is not the target of a call to <<
  def find_push_target exp
    if call? exp and exp[2] == :<<
      find_push_target exp[1]
    else
      exp
    end
  end

  def duplicate? exp
    @exp_context[0..-2].reverse_each do |e|
      return true if exp == e 
    end

    false
  end
end
