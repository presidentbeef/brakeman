require 'brakeman/checks/base_check'

#This check tests for find calls which do not use Rails' auto SQL escaping
#
#For example:
# Project.find(:all, :conditions => "name = '" + params[:name] + "'")
#
# Project.find(:all, :conditions => "name = '#{params[:name]}'")
#
# User.find_by_sql("SELECT * FROM projects WHERE name = '#{params[:name]}'")
class Brakeman::CheckSQL < Brakeman::BaseCheck
  Brakeman::Checks.add self

  @description = "Check for SQL injection"

  def run_check
    @rails_version = tracker.config[:rails_version]

    @sql_targets = [:all, :average, :calculate, :count, :count_by_sql, :exists?, :delete_all, :destroy_all,
      :find, :find_by_sql, :first, :last, :maximum, :minimum, :pluck, :sum, :update_all]
    @sql_targets.concat [:from, :group, :having, :joins, :lock, :order, :reorder, :select, :where] if tracker.options[:rails3]

    @connection_calls = [:delete, :execute, :insert, :select_all, :select_one,
      :select_rows, :select_value, :select_values]

    if tracker.options[:rails3]
      @connection_calls.concat [:exec_delete, :exec_insert, :exec_query, :exec_update]
    else
      @connection_calls.concat [:add_limit!, :add_offset_limit!, :add_lock!]
    end

    Brakeman.debug "Finding possible SQL calls on models"
    calls = tracker.find_call :targets => active_record_models.keys,
      :methods => @sql_targets,
      :chained => true

    Brakeman.debug "Finding possible SQL calls with no target"
    calls.concat tracker.find_call(:target => nil, :methods => @sql_targets)

    Brakeman.debug "Finding possible SQL calls using constantized()"
    calls.concat tracker.find_call(:methods => @sql_targets).select { |result| constantize_call? result }

    connect_targets = active_record_models.keys + [nil, :"ActiveRecord::Base"]
    calls.concat tracker.find_call(:targets => connect_targets, :methods => @connection_calls, :chained => true).select { |result| connect_call? result }

    Brakeman.debug "Finding calls to named_scope or scope"
    calls.concat find_scope_calls

    Brakeman.debug "Processing possible SQL calls"
    calls.each { |call| process_result call }
  end

  #Find calls to named_scope() or scope() in models
  #RP 3 TODO
  def find_scope_calls
    scope_calls = []

    if version_between?("2.1.0", "3.0.9")
      ar_scope_calls(:named_scope) do |name, args|
        call = make_call(nil, :named_scope, args).line(args.line)
        scope_calls << scope_call_hash(call, name, :named_scope)
      end
    elsif version_between?("3.1.0", "4.9.9")
      ar_scope_calls(:scope) do |name, args|
        second_arg = args[2]
        next unless sexp? second_arg

        if second_arg.node_type == :iter and node_type? second_arg.block, :block, :call
          process_scope_with_block(name, args)
        elsif second_arg.node_type == :call
          call = second_arg
          scope_calls << scope_call_hash(call, name, call.method)
        else
          call = make_call(nil, :scope, args).line(args.line)
          scope_calls << scope_call_hash(call, name, :scope)
        end
      end
    end

    scope_calls
  end

  def ar_scope_calls(symbol_name = :named_scope, &block)
    return_array = []
    active_record_models.each do |name, model|
      model_args = model[:options][symbol_name]
      if model_args
        model_args.each do |args|
          yield name, args
          return_array << [name, args]
        end
      end
    end
    return_array
  end

  def scope_call_hash(call, name, method)
    { :call => call, :location => { :type => :class, :class => name }, :method => :named_scope }
  end


  def process_scope_with_block model_name, args
    scope_name = args[1][1]
    block = args[-1][-1]

    # Search lambda for calls to query methods
    if block.node_type == :block
      find_calls = Brakeman::FindAllCalls.new(tracker)
      find_calls.process_source(block, :class => model_name, :method => scope_name)
      find_calls.calls.each { |call| process_result(call) if @sql_targets.include?(call[:method]) }
    elsif block.node_type == :call
      while call? block
        process_result :target => block.target, :method => block.method, :call => block,
         :location => { :type => :class, :class => model_name, :method => scope_name }

        block = block.target
      end
    end
  end

  #Process possible SQL injection sites:
  #
  # Model#find
  #
  # Model#(named_)scope
  #
  # Model#(find|count)_by_sql
  #
  # Model#all
  #
  ### Rails 3
  #
  # Model#(where|having)
  # Model#(order|group)
  #
  ### Find Options Hash
  #
  # Dangerous keys that accept SQL:
  #
  # * conditions
  # * order
  # * having
  # * joins
  # * select
  # * from
  # * lock
  #
  def process_result result
    return if duplicate?(result) or result[:call].original_line
    return if result[:target].nil? && !active_record_models.include?(result[:location][:class])
    return if result[:location] && tracker.options[:safe_methods].include?(result[:location][:method].to_s)


    call = result[:call]
    method = call.method

    dangerous_value = case method
                      when :find
                        check_find_arguments call.second_arg
                      when :exists?, :delete_all, :destroy_all
                        check_find_arguments call.first_arg
                      when :named_scope, :scope
                        check_scope_arguments call
                      when :find_by_sql, :count_by_sql
                        check_by_sql_arguments call.first_arg
                      when :calculate
                        check_find_arguments call.third_arg
                      when :last, :first, :all
                        check_find_arguments call.first_arg
                      when :average, :count, :maximum, :minimum, :sum
                        if call.length > 5
                          unsafe_sql?(call.first_arg) or check_find_arguments(call.last_arg)
                        else
                          check_find_arguments call.last_arg
                        end
                      when :where, :having
                        check_query_arguments call.arglist
                      when :order, :group, :reorder
                        check_order_arguments call.arglist
                      when :joins
                        check_joins_arguments call.first_arg
                      when :from
                        unsafe_sql? call.first_arg
                      when :lock
                        check_lock_arguments call.first_arg
                      when :pluck
                        unsafe_sql? call.first_arg
                      when :update_all, :select
                        check_update_all_arguments call.args
                      when *@connection_calls
                        check_by_sql_arguments call.first_arg
                      else
                        Brakeman.debug "Unhandled SQL method: #{method}"
                      end

    if dangerous_value
      add_result result

      input = include_user_input? dangerous_value
      if input
        confidence = CONFIDENCE[:high]
        user_input = input.match
      else
        confidence = CONFIDENCE[:med]
        user_input = dangerous_value
      end

      warn :result => result,
        :warning_type => "SQL Injection",
        :warning_code => :sql_injection,
        :message => "Possible SQL injection",
        :user_input => user_input,
        :confidence => confidence
    end

    if check_for_limit_or_offset_vulnerability call.last_arg
      if include_user_input? call.last_arg
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:low]
      end

      warn :result => result,
        :warning_type => "SQL Injection",
        :warning_code => :sql_injection_limit_offset,
        :message => "Upgrade to Rails >= 2.1.2 to escape :limit and :offset. Possible SQL injection",
        :confidence => confidence
    end
  end


  #The 'find' methods accept a number of different types of parameters:
  #
  # * The first argument might be :all, :first, or :last
  # * The first argument might be an integer ID or an array of IDs
  # * The second argument might be a hash of options, some of which are
  #   dangerous and some of which are not
  # * The second argument might contain SQL fragments as values
  # * The second argument might contain properly parameterized SQL fragments in arrays
  # * The second argument might contain improperly parameterized SQL fragments in arrays
  #
  #This method should only be passed the second argument.
  def check_find_arguments arg
    return nil if not sexp? arg or node_type? arg, :lit, :string, :str, :true, :false, :nil

    unsafe_sql? arg
  end

  def check_scope_arguments call
    scope_arg = call.second_arg #first arg is name of scope

    node_type?(scope_arg, :iter) ? unsafe_sql?(scope_arg.block) : unsafe_sql?(scope_arg)
  end

  def check_query_arguments arg
    return unless sexp? arg
    first_arg = arg[1]

    if node_type? arg, :arglist
      if arg.length > 2 and node_type? first_arg, :string_interp, :dstr
        # Model.where("blah = ?", blah)
        return check_string_interp first_arg
      else
        arg = first_arg
      end
    end

    if request_value? arg
      # Model.where(params[:where])
      arg
    elsif hash? arg
      #This is generally going to be a hash of column names and values, which
      #would escape the values. But the keys _could_ be user input.
      check_hash_keys arg
    elsif node_type? arg, :lit, :str
      nil
    else
      #Hashes are safe...but we check above for hash, so...?
      unsafe_sql? arg, :ignore_hash
    end
  end

  #Checks each argument to order/reorder/group for possible SQL.
  #Anything used with these methods is passed in verbatim.
  def check_order_arguments args
    return unless sexp? args

    if node_type? args, :arglist
      check_update_all_arguments(args)
    else
      unsafe_sql? args
    end
  end

  #find_by_sql and count_by_sql can take either a straight SQL string
  #or an array with values to bind.
  def check_by_sql_arguments arg
    return unless sexp? arg

    #This is kind of unnecessary, because unsafe_sql? will handle an array
    #correctly, but might be better to be explicit.
    array?(arg) ? unsafe_sql?(arg[1]) : unsafe_sql?(arg)
  end

  #joins can take a string, hash of associations, or an array of both(?)
  #We only care about the possible string values.
  def check_joins_arguments arg
    return unless sexp? arg and not node_type? arg, :hash, :string, :str

    if array? arg
      arg.each do |a|
        unsafe_arg = check_joins_arguments a
        return unsafe_arg if unsafe_arg
      end

      nil
    else
      unsafe_sql? arg
    end
  end

  def check_update_all_arguments args
    args.each do |arg|
      unsafe_arg = unsafe_sql? arg
      return unsafe_arg if unsafe_arg
    end

    nil
  end

  #Model#lock essentially only cares about strings. But those strings can be
  #any SQL fragment. This does not apply to all databases. (For those who do not
  #support it, the lock method does nothing).
  def check_lock_arguments arg
    return unless sexp? arg and not node_type? arg, :hash, :array, :string, :str

    unsafe_sql?(arg, :ignore_hash)
  end


  #Check hash keys for user input.
  #(Seems unlikely, but if a user can control the column names queried, that
  #could be bad)
  def check_hash_keys exp
    hash_iterate(exp) do |key, value|
      unless symbol?(key)
        unsafe_key = unsafe_sql? value
        return unsafe_key if unsafe_key
      end
    end

    false
  end

  #Check an interpolated string for dangerous values.
  #
  #This method assumes values interpolated into strings are unsafe by default,
  #unless safe_value? explicitly returns true.
  def check_string_interp arg
    arg.each do |exp|
      if dangerous = unsafe_string_interp?(exp)
        return dangerous
      end
    end

    nil
  end

  #Returns value if interpolated value is not something safe
  def unsafe_string_interp? exp
    if node_type? exp, :string_eval, :evstr
      value = exp.value
    else
      value = exp
    end

    if not sexp? value
      nil
    elsif call? value and value.method == :to_s
      unsafe_string_interp? value.target
    else
      case value.node_type
      when :or
        unsafe_string_interp?(value.lhs) || unsafe_string_interp?(value.rhs)
      when :string_interp, :dstr
        if dangerous = check_string_interp(value)
          return dangerous
        end
      else
        if safe_value? value
          nil
        elsif string_building? value
          check_for_string_building value
        else
          value
        end
      end
    end
  end

  #Checks the given expression for unsafe SQL values. If an unsafe value is
  #found, returns that value (may be the given _exp_ or a subexpression).
  #
  #Otherwise, returns false/nil.
  def unsafe_sql? exp, ignore_hash = false
    return unless sexp?(exp)

    dangerous_value = find_dangerous_value exp, ignore_hash
    safe_value?(dangerous_value) ? false : dangerous_value
  end

  #Check _exp_ for dangerous values. Used by unsafe_sql?
  def find_dangerous_value exp, ignore_hash
    case exp.node_type
    when :lit, :str, :const, :colon2, :true, :false, :nil
      nil
    when :array
      #Assume this is an array like
      #
      #  ["blah = ? AND thing = ?", ...]
      #
      #and check first value
      unsafe_sql? exp[1]
    when :string_interp, :dstr
      check_string_interp exp
    when :hash
      check_hash_values exp unless ignore_hash
    when :if
      unsafe_sql? exp.then_clause or unsafe_sql? exp.else_clause
    when :call
      unless IGNORE_METHODS_IN_SQL.include? exp.method
        if has_immediate_user_input? exp or has_immediate_model? exp
          exp
        else
          check_call exp
        end
      end
    when :or
      if unsafe = (unsafe_sql?(exp.lhs) || unsafe_sql?(exp.rhs))
        unsafe
      else
        nil
      end
    when :block, :rlist
      unsafe_sql? exp.last
    else
      if has_immediate_user_input? exp or has_immediate_model? exp
        exp
      else
        nil
      end
    end
  end

  #Checks hash values associated with these keys:
  #
  # * conditions
  # * order
  # * having
  # * joins
  # * select
  # * from
  # * lock
  def check_hash_values exp
    hash_iterate(exp) do |key, value|
      if symbol? key
        unsafe = case key.value
                 when :conditions, :having, :select
                   check_query_arguments value
                 when :order, :group
                   check_order_arguments value
                 when :joins
                   check_joins_arguments value
                 when :lock
                   check_lock_arguments value
                 when :from
                   unsafe_sql? value
                 else
                   nil
                 end

        return unsafe if unsafe
      end
    end

    false
  end

  STRING_METHODS = Set[:<<, :+, :concat, :prepend]

  def check_for_string_building exp
    return unless call? exp

    target = exp.target
    method = exp.method
    arg = exp.first_arg

    if STRING_METHODS.include? method
      if string? target
        check_string_arg arg
      elsif string? arg
        check_string_arg target
      elsif call? target
        check_for_string_building target
      elsif node_type? target, :string_interp, :dstr or
            node_type? arg, :string_interp, :dstr

        check_string_arg target and
        check_string_arg arg
      end
    else
      nil
    end
  end

  def check_string_arg exp
    if safe_value? exp
      nil
    elsif string_building? exp
      check_for_string_building exp
    elsif node_type? exp, :string_interp, :dstr
      check_string_interp exp
    elsif call? exp and exp.method == :to_s
      check_string_arg exp.target
    else
      exp
    end
  end

  def string_building? exp
    return false unless call? exp and STRING_METHODS.include? exp.method

    node_type? exp.target, :str, :dstr, :string_interp or
    node_type? exp.first_arg, :str, :dstr, :string_interp or
    string_building? exp.target or
    string_building? exp.first_arg
  end

  IGNORE_METHODS_IN_SQL = Set[:id, :merge_conditions, :table_name, :to_i, :to_f,
    :sanitize_sql, :sanitize_sql_array, :sanitize_sql_for_assignment,
    :sanitize_sql_for_conditions, :sanitize_sql_hash,
    :sanitize_sql_hash_for_assignment, :sanitize_sql_hash_for_conditions,
    :to_sql, :sanitize]

  def safe_value? exp
    return true unless sexp? exp

    case exp.node_type
    when :str, :lit, :const, :colon2, :nil, :true, :false
      true
    when :call
      if exp.method == :to_s
        safe_value? exp.target
      else
        IGNORE_METHODS_IN_SQL.include? exp.method or
        quote_call? exp or
        exp.method.to_s.end_with? "_id"
      end
    when :if
      safe_value? exp.then_clause and safe_value? exp.else_clause
    when :block, :rlist
      safe_value? exp.last
    when :or
      safe_value? exp.lhs and safe_value? exp.rhs
    else
      false
    end
  end

  QUOTE_METHODS = [:quote, :quote_column_name, :quoted_date, :quote_string, :quote_table_name]

  def quote_call? exp
    if call? exp.target
      exp.target.method == :connection and QUOTE_METHODS.include? exp.method
    elsif exp.target.nil?
      exp.method == :quote_value
    end
  end

  #Check call for string building
  def check_call exp
    return unless call? exp
    unsafe = check_for_string_building exp

    if unsafe
      unsafe
    elsif call? exp.target
      check_call exp.target
    else
      nil
    end
  end

  #Prior to Rails 2.1.1, the :offset and :limit parameters were not
  #escaping input properly.
  #
  #http://www.rorsecurity.info/2008/09/08/sql-injection-issue-in-limit-and-offset-parameter/
  def check_for_limit_or_offset_vulnerability options
    return false if @rails_version.nil? or @rails_version >= "2.1.1" or not hash?(options)

    return true if hash_access(options, :limit) or hash_access(options, :offset)

    false
  end

  #Look for something like this:
  #
  # params[:x].constantize.find('something')
  #
  # s(:call,
  #   s(:call,
  #     s(:call,
  #       s(:call, nil, :params, s(:arglist)),
  #       :[],
  #       s(:arglist, s(:lit, :x))),
  #     :constantize,
  #     s(:arglist)),
  #   :find,
  #   s(:arglist, s(:str, "something")))
  def constantize_call? result
    call = result[:call]
    call? call.target and call.target.method == :constantize
  end

  SELF_CLASS = s(:call, s(:self), :class)

  def connect_call? result
    call = result[:call]
    target = call.target

    if call? target and target.method == :connection
      target = target.target
      klass = class_name(target)

      target.nil? or
      target == SELF_CLASS or
      node_type? target, :self or
      klass == :"ActiveRecord::Base" or
      active_record_models.include? klass
    end
  end
end
