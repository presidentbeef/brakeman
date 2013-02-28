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
      :find, :find_by_sql, :first, :last, :maximum, :minimum, :pluck, :sum, :update_all]

    if tracker.options[:rails3]
      @sql_targets.concat [:from, :group, :having, :joins, :lock, :order, :reorder, :select, :where]
    end

    Brakeman.debug "Finding possible SQL calls on models"
    calls = tracker.find_call :targets => active_record_models.keys,
      :methods => @sql_targets,
      :chained => true

    Brakeman.debug "Finding possible SQL calls with no target"
    calls.concat tracker.find_call(:target => nil, :method => @sql_targets)

    Brakeman.debug "Finding possible SQL calls using constantized()"
    calls.concat tracker.find_call(:method => @sql_targets).select { |result| constantize_call? result }

    Brakeman.debug "Finding calls to named_scope or scope"
    calls.concat find_scope_calls

    Brakeman.debug "Checking version of Rails for CVE-2012-2660"
    check_rails_version_for_cve_2012_2660

    Brakeman.debug "Checking version of Rails for CVE-2012-2661"
    check_rails_version_for_cve_2012_2661

    Brakeman.debug "Checking version of Rails for CVE-2012-2695"
    check_rails_version_for_cve_2012_2695

    Brakeman.debug "Checking version of Rails for CVE-2012-5664"
    check_rails_version_for_cve_2012_5664

    Brakeman.debug "Checking version of Rails for CVE-2013-0155"
    check_rails_version_for_cve_2013_0155

    Brakeman.debug "Processing possible SQL calls"
    calls.each do |c|
      process_result c
    end
  end

  #Find calls to named_scope() or scope() in models
  #RP 3 TODO
  def find_scope_calls
    scope_calls = []

    if version_between? "2.1.0", "3.0.9"
      active_record_models.each do |name, model|
        if model[:options][:named_scope]
          model[:options][:named_scope].each do |args|
            call = make_call(nil, :named_scope, args).line(args.line)
            scope_calls << { :call => call, :location => [:class, name ], :method => :named_scope }
          end
        end
       end
    elsif version_between? "3.1.0", "3.9.9"
      active_record_models.each do |name, model|
        if model[:options][:scope]
          model[:options][:scope].each do |args|
            second_arg = args[2]

            next unless sexp? second_arg

            if second_arg.node_type == :iter and node_type? second_arg.block, :block, :call
              process_scope_with_block name, args
            elsif second_arg.node_type == :call
              call = second_arg
              scope_calls << { :call => call, :location => [:class, name ], :method => call.method }
            else
              call = make_call(nil, :scope, args).line(args.line)
              scope_calls << { :call => call, :location => [:class, name ], :method => :scope }
            end
          end
        end
      end
    end

    scope_calls
  end

  def check_rails_version_for_cve_2012_2660
    if version_between?("2.0.0", "2.3.14") || version_between?("3.0.0", "3.0.12") || version_between?("3.1.0", "3.1.4") || version_between?("3.2.0", "3.2.3")
      warn :warning_type => 'SQL Injection',
        :warning_code => :CVE_2012_2660,
        :message => 'All versions of Rails before 3.0.13, 3.1.5, and 3.2.5 contain a SQL Query Generation Vulnerability: CVE-2012-2660; Upgrade to 3.2.5, 3.1.5, 3.0.13',
        :confidence => CONFIDENCE[:high],
        :file => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/8SA-M3as7A8/discussion"
    end
  end

  def check_rails_version_for_cve_2012_2661
    if version_between?("3.0.0", "3.0.12") || version_between?("3.1.0", "3.1.4") || version_between?("3.2.0", "3.2.3")
      warn :warning_type => 'SQL Injection',
        :warning_code => :CVE_2012_2661,
        :message => 'All versions of Rails before 3.0.13, 3.1.5, and 3.2.5 contain a SQL Injection Vulnerability: CVE-2012-2661; Upgrade to 3.2.5, 3.1.5, 3.0.13',
        :confidence => CONFIDENCE[:high],
        :file => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/dUaiOOGWL1k/discussion"
    end
  end

  def check_rails_version_for_cve_2012_2695
    if version_between?("2.0.0", "2.3.14") || version_between?("3.0.0", "3.0.13") || version_between?("3.1.0", "3.1.5") || version_between?("3.2.0", "3.2.5")
      warn :warning_type => 'SQL Injection',
        :warning_code => :CVE_2012_2695,
        :message => 'All versions of Rails before 3.0.14, 3.1.6, and 3.2.6 contain SQL Injection Vulnerabilities: CVE-2012-2694 and CVE-2012-2695; Upgrade to 3.2.6, 3.1.6, 3.0.14',
        :confidence => CONFIDENCE[:high],
        :file => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/l4L0TEVAz1k/discussion"
    end
  end

  def check_rails_version_for_cve_2012_5664
    if version_between?("2.0.0", "2.3.14") || version_between?("3.0.0", "3.0.17") || version_between?("3.1.0", "3.1.8") || version_between?("3.2.0", "3.2.9")
      warn :warning_type => 'SQL Injection',
        :warning_code => :CVE_2012_5664,
        :message => 'All versions of Rails before 3.0.18, 3.1.9, and 3.2.10 contain a SQL Injection Vulnerability: CVE-2012-5664; Upgrade to 3.2.10, 3.1.9, 3.0.18',
        :confidence => CONFIDENCE[:high],
        :file => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/DCNTNp_qjFM/discussion"
    end
  end

  def check_rails_version_for_cve_2013_0155
    if version_between?("3.0.0", "3.0.18") || version_between?("3.1.0", "3.1.9") || version_between?("3.2.0", "3.2.10")
      message = 'All versions of Rails before 3.0.19, 3.1.10, and 3.2.11 contain a SQL Injection Vulnerability: CVE-2013-0155; Upgrade to 3.2.11, 3.1.10, 3.0.19'
    elsif version_between?("2.0.0", "2.3.15")
      message = "Rails #{@rails_version} contains a SQL Injection Vulnerability: CVE-2013-0155; Upgrade to 2.3.16"
    end

    if message
      warn :warning_type => 'SQL Injection',
        :warning_code => :CVE_2013_0155,
        :message => message,
        :confidence => CONFIDENCE[:high],
        :file => gemfile_or_environment,
        :link_path => "https://groups.google.com/d/topic/rubyonrails-security/c7jT-EeN9eI/discussion"
    end
  end

  def process_scope_with_block model_name, args
    scope_name = args[1][1]
    block = args[-1][-1]

    #Search lambda for calls to query methods
    if block.node_type == :block
      find_calls = Brakeman::FindAllCalls.new tracker

      find_calls.process_source block, model_name, scope_name

      find_calls.calls.each do |call|
        if @sql_targets.include? call[:method]
          process_result call
        end
      end
    elsif block.node_type == :call
      process_result :target => block.target, :method => block.method, :call => block, :location => [:class, model_name, scope_name]
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
    method = call.method

    dangerous_value = case method
                      when :find
                        check_find_arguments call.second_arg
                      when :exists?
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
                      when :from, :select
                        unsafe_sql? call.first_arg
                      when :lock
                        check_lock_arguments call.first_arg
                      when :pluck
                        unsafe_sql? call.first_arg
                      when :update_all
                        check_update_all_arguments call.args
                      else
                        Brakeman.debug "Unhandled SQL method: #{method}"
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
    if not sexp? arg or node_type? arg, :lit, :string, :str, :true, :false, :nil
      return nil
    end

    unsafe_sql? arg
  end

  def check_scope_arguments call
    scope_arg = call.second_arg #first arg is name of scope

    if node_type? scope_arg, :iter
      unsafe_sql? scope_arg.block
    else
      unsafe_sql? scope_arg
    end
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
      args.each do |arg|
        if unsafe_arg = unsafe_sql?(arg)
          return unsafe_arg
        end
      end

      nil
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

  def check_update_all_arguments args
    args.each do |arg|
      res = unsafe_sql? arg
      return res if res
    end

    nil
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
      if node_type?(exp, :string_eval, :evstr) and not safe_value? exp.value
        return exp.value
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
        return unsafe
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

    if string? target or string? exp.first_arg
      if STRING_METHODS.include? method
        return exp
      end
    elsif STRING_METHODS.include? method and call? target
      unsafe_sql? target
    end
  end

  IGNORE_METHODS_IN_SQL = Set[:id, :merge_conditions, :table_name, :to_i, :to_f,
    :sanitize_sql, :sanitize_sql_array, :sanitize_sql_for_assignment,
    :sanitize_sql_for_conditions, :sanitize_sql_hash,
    :sanitize_sql_hash_for_assignment, :sanitize_sql_hash_for_conditions,
    :to_sql]

  def safe_value? exp
    return true unless sexp? exp

    case exp.node_type
    when :str, :lit, :const, :colon2, :nil, :true, :false
      true
    when :call
      IGNORE_METHODS_IN_SQL.include? exp.method
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

  #Check call for string building
  def check_call exp
    return unless call? exp

    if unsafe = check_for_string_building(exp)
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
    return false if @rails_version.nil? or @rails_version >= "2.1.1" or not hash? options

    if hash_access(options, :limit) or hash_access(options, :offset)
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
    call? call.target and call.target.method == :constantize
  end
end
