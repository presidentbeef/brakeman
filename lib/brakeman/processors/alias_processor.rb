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
    @inside_if = []
    @ignore_ifs = nil
    @exp_context = []
    @current_module = nil
    @tracker = tracker #set in subclass as necessary
    @helper_method_cache = {}
    @helper_method_info = Hash.new({})
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
    @env = set_env || SexpProcessor::Environment.new
    @result = src.deep_clone
    process @result
    @result
  end

  #Process a Sexp. If the Sexp has a value associated with it in the
  #environment, that value will be returned.
  def process_default exp
    @exp_context.push exp

    begin
      exp.map! do |e|
        if sexp? e and not e.empty?
          process e
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
    first_arg = exp.first_arg

    if node_type? target, :or and [:+, :-, :*, :/].include? method
      res = process_or_simple_operation(exp)
      return res if res
    end

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
          target.first_arg = Sexp.new(:lit, target.first_arg.value + first_arg.value)
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
        temp_exp = process_hash_access target, first_arg
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
      exp.body = process_all! exp.body
    end
    exp
  end

  #Process a method definition on self.
  def process_selfdef exp
    env.scope do
      set_env_defaults
      exp.body = process_all! exp.body
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

    set_value local, exp.rhs

    exp
  end

  #Instance variable assignment
  # @x = 1
  def process_iasgn exp
    exp.rhs = process exp.rhs
    ivar = Sexp.new(:ivar, exp.lhs).line(exp.line)

    set_value ivar, exp.rhs

    exp
  end

  #Global assignment
  # $x = 1
  def process_gasgn exp
    match = Sexp.new(:gvar, exp.lhs)
    value = exp.rhs = process(exp.rhs)

    set_value match, value, exp.line

    exp
  end

  #Class variable assignment
  # @@x = 1
  def process_cvdecl exp
    match = Sexp.new(:cvar, exp.lhs)
    value = exp.rhs = process(exp.rhs)

    set_value match, value, exp.line

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
    index_arg = exp.first_arg
    value_arg = exp.second_arg

    if method == :[]=
      index = exp.first_arg = process(index_arg)
      value = exp.second_arg = process(value_arg)
      match = Sexp.new(:call, target, :[], index)

      set_value match, value, exp.line

      if hash? target
        env[tar_variable] = hash_insert target.deep_clone, index, value
      end
    elsif method.to_s[-1,1] == "="
      value = exp.first_arg = process(index_arg)
      #This is what we'll replace with the value
      match = Sexp.new(:call, target, method.to_s[0..-2].to_sym)

      set_value match, value, exp.line
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
      match = Sexp.new(:call, hash, :[], key)
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
    match = Sexp.new(:call, target, :[], index)

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

    match = Sexp.new(:call, target, method.to_s[0..-2].to_sym)

    unless env[match]
      env[match] = value
    end

    exp
  end

  #This is the right hand side value of a multiple assignment,
  #like `x = y, z`
  def process_svalue exp
    exp.value
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
    if @ignore_ifs.nil?
      @ignore_ifs = @tracker && @tracker.options[:ignore_ifs]
    end

    condition = process exp.condition

    if true? condition
      no_branch = true
      exps = [exp.then_clause]
    elsif false? condition
      no_branch = true
      exps = [exp.else_clause]
    else
      no_branch = false
      exps = [exp.then_clause, exp.else_clause]
    end

    exps.each do |e|
      @inside_if << [] unless no_branch or @ignore_ifs

      if sexp? e
        if e.node_type == :block
          process_default e #avoid creating new scope
        else
          process e
        end
      end

      @inside_if.pop unless no_branch or @ignore_ifs
    end

    exp
  end

  #Process single integer access to an array.
  #
  #Returns the value inside the array, if possible.
  def process_array_access target, args
    if args.length == 1 and integer? args.first
      index = args.first.value

      #Have to do this because first element is :array and we have to skip it
      target[1..-1][index]
    else
      nil
    end
  end

  #Process hash access by returning the value associated
  #with the given argument.
  def process_hash_access target, index
    hash_access(target, index)
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
    result.value = string1.value + string2.value

    if result.value.length > 50
      string1
    else
      result
    end
  end

  #Returns a new SexpProcessor::Environment containing only instance variables.
  #This is useful, for example, when processing views.
  def only_ivars include_request_vars = false, lenv = nil
    lenv ||= env
    res = SexpProcessor::Environment.new

    if include_request_vars
      lenv.all.each do |k, v|
        #TODO Why would this have nil values?
        if (k.node_type == :ivar or request_value? k) and not v.nil?
          res[k] = v.dup
        end
      end
    else
      lenv.all.each do |k, v|
        #TODO Why would this have nil values?
        if k.node_type == :ivar and not v.nil?
          res[k] = v.dup
        end
      end
    end

    res
  end

  def only_request_vars
    res = SexpProcessor::Environment.new

    env.all.each do |k, v|
      if request_value? k and not v.nil?
        res[k] = v.dup
      end
    end

    res
  end

  def get_call_value call
    method_name = call.method

    #Look for helper methods and see if we can get a return value
    if found_method = find_method(method_name, @current_class)
      helper = found_method[:method]

      if sexp? helper
        value = process_helper_method helper, call.args
        value.line(call.line)
        return value
      else
        raise "Unexpected value for method: #{found_method}"
      end
    else
      call
    end
  end

  def process_helper_method method_exp, args
    method_name = method_exp.method_name
    Brakeman.debug "Processing method #{method_name}"

    info = @helper_method_info[method_name]

    #If method uses instance variables, then include those and request
    #variables (params, etc) in the method environment. Otherwise,
    #only include request variables.
    if info[:uses_ivars]
      meth_env = only_ivars(:include_request_vars)
    else
      meth_env = only_request_vars
    end

    #Add arguments to method environment
    assign_args method_exp, args, meth_env


    #Find return values if method does not depend on environment/args
    values = @helper_method_cache[method_name]

    unless values
      #Serialize environment for cache key
      meth_values = meth_env.instance_variable_get(:@env).to_a
      meth_values.sort!
      meth_values = meth_values.to_s

      digest = Digest::SHA1.new.update(meth_values << method_name.to_s).to_s.to_sym

      values = @helper_method_cache[digest]
    end

    if values
      #Use values from cache
      values[:ivar_values].each do |var, val|
        env[var] = val
      end

      values[:return_value]
    else
      #Find return value for method
      frv = Brakeman::FindReturnValue.new
      value = frv.get_return_value(method_exp.body_list, meth_env)

      ivars = {}

      only_ivars(false, meth_env).all.each do |var, val|
        env[var] = val
        ivars[var] = val
      end

      if not frv.uses_ivars? and args.length == 0
        #Store return value without ivars and args if they are not used
        @helper_method_cache[method_exp.method_name] = { :return_value => value, :ivar_values => ivars }
      else
        @helper_method_cache[digest] = { :return_value => value, :ivar_values => ivars }
      end

      #Store information about method, just ivar usage for now
      @helper_method_info[method_name] = { :uses_ivars => frv.uses_ivars? }

      value
    end
  end

  def assign_args method_exp, args, meth_env = SexpProcessor::Environment.new
    formal_args = method_exp.formal_args

    formal_args.each_with_index do |arg, index|
      next if index == 0

      if arg.is_a? Symbol and sexp? args[index - 1]
        meth_env[Sexp.new(:lvar, arg)] = args[index - 1]
      end
    end

    meth_env
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
    if call? exp and exp.method == :<<
      find_push_target exp.target
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

  def find_method *args
    nil
  end

  #Return true if this value should be "branched" - i.e. converted into an or
  #expression with two or more values
  def branch_value? exp
    not (@inside_if.empty? or @inside_if.last.include? exp)
  end

  #Return true if lhs == rhs or lhs is an or expression and
  #rhs is one of its values
  def same_value? lhs, rhs
    if lhs == rhs
      true
    elsif node_type? lhs, :or
      lhs.rhs == rhs or lhs.lhs == rhs
    else
      false
    end
  end

  #Set variable to given value.
  #Creates "branched" versions of values when appropriate.
  #Avoids creating multiple branched versions inside same
  #if branch.
  def set_value var, value, line = nil
    unless @ignore_ifs
      current_val = env[var]
      current_if = @inside_if.last

      if branch_value? var and current_val = env[var]
        unless same_value? current_val, value
          env[var] = Sexp.new(:or, current_val, value).line(line || var.line || -2)
          current_if << var
        end
      elsif current_if and current_if.include?(var) and node_type?(current_val, :or)
        #Replace last value instead of creating another or
        current_val.rhs = value
      else
        env[var] = value

        if current_if
          current_if << var
        end
      end
    else
      env[var] = value
    end
  end

  #If possible, distribute operation over both sides of an or.
  #For example,
  #
  #    (1 or 2) * 5
  #
  #Becomes
  #
  #    (5 or 10)
  #
  #Only works for strings and numbers right now.
  def process_or_simple_operation exp
    arg = exp.first_arg
    return nil unless string? arg or number? arg

    target = exp.target
    lhs = process_or_target(target.lhs, exp.dup)
    rhs = process_or_target(target.rhs, exp.dup)

    if lhs and rhs
      if same_value? lhs, rhs
        lhs
      else
        exp.target.lhs = lhs
        exp.target.rhs = rhs
        exp.target
      end
    else
      nil
    end
  end

  def process_or_target value, copy
    if string? value or number? value
      copy.target = value
      process copy
    else
      false
    end
  end

end
