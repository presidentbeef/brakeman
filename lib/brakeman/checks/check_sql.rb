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

  def run_check
    @rails_version = tracker.config[:rails_version]

    debug_info "Finding possible SQL calls on models"
    if tracker.options[:rails3]
      calls = tracker.find_call :targets => tracker.models.keys,
        :methods => /^(find.*|first|last|all|where|order|group|having)$/,
        :chained => true
    else
      calls = tracker.find_call :targets => tracker.models.keys,
        :methods => /^(find.*|first|last|all)$/,
        :chained => true
    end

    debug_info "Finding possible SQL calls with no target"
    calls.concat tracker.find_call(:target => nil, :method => /^(find.*|last|first|all|count|sum|average|minumum|maximum|count_by_sql)$/)

    debug_info "Finding possible SQL calls using constantized()"
    calls.concat tracker.find_call(:method => /^(find.*|last|first|all|count|sum|average|minumum|maximum|count_by_sql)$/).select { |result| constantize_call? result }

    debug_info "Finding calls to named_scope or scope"
    calls.concat find_scope_calls

    debug_info "Processing possible SQL calls"
    calls.each do |c|
      process_result c
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
            scope_calls << { :call => call, :location => [:class, name ] }
          end
        end
       end
    elsif version_between? "3.1.0", "3.9.9"
      tracker.models.each do |name, model|
        if model[:options][:scope]
          model[:options][:scope].each do |args|
            call = Sexp.new(:call, nil, :scope, args).line(args.line)
            scope_calls << { :call => call, :location => [:class, name ] }
          end
        end
      end
    end

    scope_calls
  end

  #Process result from Tracker#find_call.
  def process_result result
    call = result[:call]

    args = call[3]

    if call[2] == :find_by_sql or call[2] == :count_by_sql
      failed = check_arguments args[1]
    elsif call[2].to_s =~ /^find/
      failed = (args.length > 2 and check_arguments args[-1])
    else
      failed = (args.length > 1 and check_arguments args[-1])
    end

    if failed and not call.original_line and not duplicate? result
      add_result result

      if include_user_input? args[-1]
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:med]
      end

      warn :result => result,
        :warning_type => "SQL Injection",
        :message => "Possible SQL injection",
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

  private

  #Check arguments for any string interpolation
  def check_arguments arg
    if sexp? arg
      case arg.node_type
      when :hash
        hash_iterate(arg) do |key, value|
          if check_arguments value
            return true
          end
        end
      when :array
        return check_arguments(arg[1])
      when :string_interp, :dstr
        return true if check_string_interp arg
      when :call
        return check_call(arg)
      else
        return arg.any? do |a|
          check_arguments(a)
        end
      end
    end

    false
  end

  def check_string_interp arg
    arg.each do |exp|
      #For now, don't warn on interpolation of Model.table_name
      #but check for other 'safe' things in the future
      if sexp? exp and (exp.node_type == :string_eval or exp.node_type == :evstr)
        if call? exp[1] and (model_name?(exp[1][1]) or exp[1][1].nil?) and exp[1][2] == :table_name
          return false
        end
      end
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
    elsif target == nil and tracker.options[:rails3] and method.to_s.match /^first|last|all|where|order|group|having$/
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

    hash_iterate(options) do |key, value|
      if symbol? key
        return (key[1] == :limit or key[1] == :offset)
      end
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
