require 'brakeman/processors/lib/basic_processor'

#Finds method calls matching the given target(s).
#   #-- This should be deprecated --#
#   #--  Do not use for new code  --#
#
#Targets/methods can be:
#
# - nil: matches anything, including nothing
# - Empty array: matches nothing
# - Symbol: matches single target/method exactly
# - Array of symbols: matches against any of the symbols
# - Regular expression: matches the expression
# - Array of regular expressions: matches any of the expressions
#
#If a target is also the name of a class, methods called on instances
#of that class will also be matched, in a very limited way.
#(Any methods called on Klass.new, basically. More useful when used
#in conjunction with AliasProcessor.)
#
#Examples:
#
# #To find any uses of this class:
# FindCall.new :FindCall, nil
#
# #Find system calls without a target
# FindCall.new [], [:system, :exec, :syscall]
#
# #Find all calls to length(), no matter the target
# FindCall.new nil, :length
#
# #Find all calls to sub, sub!, gsub, or gsub!
# FindCall.new nil, /^g?sub!?$/
class Brakeman::FindCall < Brakeman::BasicProcessor

  def initialize targets, methods, tracker, in_depth = false
    super tracker
    @calls = []
    @find_targets = targets
    @find_methods = methods
    @current_class = nil
    @current_method = nil
    @in_depth = in_depth
  end

  #Returns a list of results.
  #
  #A result looks like:
  #
  # s(:result, :ClassName, :method_name, s(:call, ...))
  #
  #or
  #
  # s(:result, :template_name, s(:call, ...))
  def matches
    @calls
  end

  #Process the given source. Provide either class and method being searched
  #or the template. These names are used when reporting results.
  #
  #Use FindCall#matches to retrieve results.
  def process_source exp, klass = nil, method = nil, template = nil
    @current_class = klass
    @current_method = method
    @current_template = template
    process exp
  end

  #Process body of method
  def process_defn exp
    process_all exp.body
  end

  alias :process_defs :process_defn

  #Process body of block
  def process_rlist exp
    process_all exp
  end

  #Look for matching calls and add them to results
  def process_call exp
    target = get_target exp.target
    method = exp.method

    process_call_args exp

    if match(@find_targets, target) and match(@find_methods, method)

      if @current_template
        @calls << Sexp.new(:result, @current_template, exp).line(exp.line)
      else
        @calls << Sexp.new(:result, @current_module, @current_class, @current_method, exp).line(exp.line)
      end

    end
    
    #Normally FindCall won't match a method invocation that is the target of
    #another call, such as:
    #
    #  User.find(:first, :conditions => "user = '#{params['user']}').name
    #
    #A search for User.find will not match this unless @in_depth is true.
    if @in_depth and call? exp.target
      process exp.target
    end

    exp
  end

  #Process an assignment like a call
  def process_attrasgn exp
    process_call exp
  end

  private

  #Gets the target of a call as a Symbol
  #if possible
  def get_target exp
    if sexp? exp
      case exp.node_type
      when :ivar, :lvar, :const, :lit
        exp.value
      when :true, :false
        exp.node_type
      when :colon2
        class_name exp
      else
        exp
      end
    else
      exp
    end
  end

  #Checks if the search terms match the given item
  def match search_terms, item
    case search_terms
    when Symbol
      if search_terms == item
        true
      elsif sexp? item
        is_instance_of? item, search_terms
      else
        false
      end
    when Sexp
      search_terms == item
    when Enumerable
      if search_terms.empty?
        item == nil
      else
        search_terms.each do|term|
          if match(term, item)
            return true
          end
        end
        false
      end
    when Regexp
      search_terms.match item.to_s
    when nil
      true
    else
      raise "Cannot match #{search_terms} and #{item}"
    end
  end

  #Checks if +item+ is an instance of +klass+ by looking for Klass.new
  def is_instance_of? item, klass
    if call? item
      if sexp? item.target
        item.method == :new and item.target.node_type == :const and item.target.value == klass
      else
        item.method == :new and item.target == klass
      end
    else
      false
    end
  end
end
