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

    @sql_targets = [:all, :average, :calculate, :count, :count_by_sql, :exists?,
      :find, :find_by_sql, :first, :last, :maximum, :minumum, :sum]

    if tracker.options[:rails3]
      @sql_targets.concat [:from, :group, :having, :joins, :lock, :order, :reorder, :where]
    end

    Brakeman.debug "Finding possible SQL calls on models"
    calls = tracker.find_call :targets => tracker.models.keys,
      :methods => @sql_targets,
      :chained => true

    Brakeman.debug "Finding possible SQL calls with no target"
    calls.concat tracker.find_call(:target => nil, :method => @sql_targets)

    Brakeman.debug "Finding possible SQL calls using constantized()"
    calls.concat tracker.find_call(:method => @sql_targets).select { |result| constantize_call? result }

    Brakeman.debug "Finding calls to named_scope or scope"
    calls.concat find_scope_calls

    Brakeman.debug "Processing possible SQL calls"
    calls.each do |c|
      begin
        process_result c
      rescue Exception => e
        p e
        puts e.backtrace
      end
    end
  end

  #Find calls to named_scope() or scope() in models
  def find_scope_calls
    scope_calls = []

    if version_between? "2.1.0", "3.0.9"
      tracker.models.each do |name, model|
        if model[:options][:named_scope]
          model[:options][:named_scope].each do |args|
            call = Sexp.new(:call, nil, :named_scope, args).line(args.line)
            scope_calls << { :call => call, :location => [:class, name ], :method => :named_scope }
          end
        end
       end
    elsif version_between? "3.1.0", "3.9.9"
      tracker.models.each do |name, model|
        if model[:options][:scope]
          model[:options][:scope].each do |args|
            second_arg = args[2]

            if second_arg.node_type == :iter and
              (second_arg[-1].node_type == :block or second_arg[-1].node_type == :call)
              process_scope_with_block name, args
            elsif second_arg.node_type == :call
              call = second_arg
              scope_calls << { :call => call, :location => [:class, name ], :method => call[2] }
            else
              call = Sexp.new(:call, nil, :scope, args).line(args.line)
              scope_calls << { :call => call, :location => [:class, name ], :method => :scope }
            end
          end
        end
      end
    end

    scope_calls
  end

  def process_scope_with_block model_name, args
    scope_name = args[1][1]
    block = args[-1][-1]

    #Search lambda for calls to query methods
    if block.node_type == :block
      find_calls = Brakeman::FindAllCalls.new tracker

      find_calls.process_source block, model_name, scope_name

      find_calls.calls.each do |call|
        if call[:method].to_s =~ @sql_targets
          process_result call
        end
      end
    elsif block.node_type == :call
      process_result :target => block[1], :method => block[2], :call => block, :location => [:class, model_name, scope_name]
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
    return if duplicate? result or result[:call].original_line

    call = result[:call]
    method = call[2]
    args = call[3]

    dangerous_value = case method
                      when :find
                        check_find_arguments args[2]
                      when :exists?
                        check_find_arguments args[1]
                      when :named_scope, :scope
                        check_scope_arguments args
                      when :find_by_sql, :count_by_sql
                        check_by_sql_arguments args[1]
                      when :calculate
                        check_find_arguments args[3]
                      when :last, :first, :all, :count, :sum, :average, :maximum, :minimum
                        check_find_arguments args[1]
                      when :where, :having
                        check_query_arguments args
                      when :order, :group, :reorder
                        check_order_arguments args
                      when :joins
                        check_joins_arguments args[1]
                      when :from
                        unsafe_sql? args[1]
                      when :lock
                        check_lock_arguments args[1]
                      else
                        Brakeman.notify "Method: #{method}"
                      end

    if dangerous_value
      add_result result

      if input = include_user_input?(dangerous_value)
        confidence = CONFIDENCE[:high]
        user_input = input.match
      else
        confidence = CONFIDENCE[:med]
        user_input = dangerous_value
      end

      warn :result => result,
        :warning_type => "SQL Injection",
        :message => "Possible SQL injection",
        :user_input => user_input,
        :confidence => confidence
    end

    if check_for_limit_or_offset_vulnerability args[-1]
      if include_user_input? args[-1]
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:low]
      end

      warn :result => result,
        :warning_type => "SQL Injection",
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
    if not sexp? arg or node_type? arg, :lit, :string, :str, :true, :false, :nil
      return nil
    end

    unsafe_sql? arg
  end

  def check_scope_arguments args
    return unless node_type? args, :arglist

    if node_type? args[2], :iter
      args[2][-1].find do |arg|
        unsafe_sql? arg
      end
    else
      unsafe_sql? args[2]
    end
  end

  def check_query_arguments arg
    return unless sexp? arg

    if node_type? arg, :arglist
      if arg.length > 2 and node_type? arg[1], :string_interp, :dstr
        # Model.where("blah = ?", blah)
        return string_interp arg[1]
      else
        arg = arg[1]
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

    args.each do |arg|
      if unsafe_arg = unsafe_sql?(arg)
        return unsafe_arg
      end
    end

    nil
  end

  #find_by_sql and count_by_sql can take either a straight SQL string
  #or an array with values to bind.
  def check_by_sql_arguments arg
    return unless sexp? arg

    #This is kind of necessary, because unsafe_sql? will handle an array
    #correctly, but might be better to be explicit.
    if array? arg
      unsafe_sql? arg[1]
    else
      unsafe_sql? arg
    end
  end

  #joins can take a string, hash of associations, or an array of both(?)
  #We only care about the possible string values.
  def check_joins_arguments arg
    return unless sexp? arg and not node_type? arg, :hash, :string, :str

    if array? arg
      arg.each do |a|
        if unsafe = check_joins_arguments(a)
          return unsafe
        end
      end

      nil
    else
      unsafe_sql? arg
    end
  end

  #Model#lock essentially only cares about strings. But those strings can be
  #any SQL fragment. This does not apply to all databases. (For those who do not
  #support it, the lock method does nothing).
  def check_lock_arguments arg
    return unless sexp? arg and not node_type? arg, :hash, :array, :string, :str

    unsafe_sql? arg, :ignore_hash
  end


  #Check hash keys for user input.
  #(Seems unlikely, but if a user can control the column names queried, that
  #could be bad)
  def check_hash_keys exp
    hash_iterate(exp) do |key, value|
      unless symbol? key
        if unsafe_key = unsafe_sql?(value)
          return unsafe_key
        end
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
      if node_type?(exp, :string_eval, :evstr) and not safe_value? exp[1]
        return exp[1]
      end
    end

    nil
  end

  #Checks the given expression for unsafe SQL values. If an unsafe value is
  #found, returns that value (may be the given _exp_ or a subexpression).
  #
  #Otherwise, returns false/nil.
  def unsafe_sql? exp, ignore_hash = false
    return unless sexp? exp

    dangerous_value = find_dangerous_value exp, ignore_hash

    if safe_value? dangerous_value
      false
    else
      dangerous_value
    end
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
      unsafe_sql? exp[2] or unsafe_sql? exp[3]
    when :call
      if has_immediate_user_input? exp or has_immediate_model? exp
        exp
      else
        nil
      end
      #elsif unsafe = check_for_string_building exp
      #  return unsafe
      #else
      #  nil
      #end
    when :or
      if unsafe = (unsafe_sql?(exp[1]) || unsafe_sql?(exp[2]))
        return unsafe
      else
        nil
      end
    else
      if has_immediate_user_input? exp or has_immediate_model? exp
        exp
      else
        puts "unsafe? #{exp.inspect}"
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
        unsafe = case key[1]
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


  IGNORE_METHODS_IN_SQL = Set[:id, :table_name]

  def safe_value? exp
    return true unless sexp? exp

    case exp.node_type
    when :str, :lit, :const, :colon2
      true
    when :call
      IGNORE_METHODS_IN_SQL.include? exp[3]
    else
      false
    end
  end

  #Check call for user input and string building
  def check_call exp
    target = exp[1]
    method = exp[2]
    args = exp[3]

    if sexp? target and
      (method == :+ or method == :<< or method == :concat) and
      (string? target or include_user_input? exp)

      true
    elsif call? target
      check_call target
    elsif target == nil and tracker.options[:rails3] and method.to_s.match(/^first|last|all|where|order|group|having$/)
      check_arguments args
    else
      false
    end
  end

  #Prior to Rails 2.1.1, the :offset and :limit parameters were not
  #escaping input properly.
  #
  #http://www.rorsecurity.info/2008/09/08/sql-injection-issue-in-limit-and-offset-parameter/
  def check_for_limit_or_offset_vulnerability options
    return false if @rails_version.nil? or @rails_version >= "2.1.1" or not hash? options

    if hash_access(options, :limit) or hash_access(options[:offset])
      return true
    end

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
    call? call[1] and call[1][2] == :constantize
  end
end
