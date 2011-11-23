require 'brakeman/processors/base_processor'

#Finds method calls matching the given target(s).
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
class Brakeman::FindCall < Brakeman::BaseProcessor

  def initialize targets, methods, in_depth = false
    super(nil)
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
  def process_methdef exp
    process exp[3]
  end

  #Process body of method
  def process_selfdef exp
    process exp[4]
  end

  #Process body of block
  def process_rlist exp
    exp[1..-1].each do |e|
      process e
    end

    exp
  end

  #Look for matching calls and add them to results
  def process_call exp
    target = get_target exp[1] 
    method = exp[2]

    process exp[3]

    if match(@find_targets, target) and match(@find_methods, method)

      if @current_template
        @calls << Sexp.new(:result, @current_template, exp).line(exp.line)
      else
        @calls << Sexp.new(:result, @current_class, @current_method, exp).line(exp.line)
      end

    end
    
    #Normally FindCall won't match a method invocation that is the target of
    #another call, such as:
    #
    #  User.find(:first, :conditions => "user = '#{params['user']}').name
    #
    #A search for User.find will not match this unless @in_depth is true.
    if @in_depth and sexp? exp[1] and exp[1][0] == :call
      process exp[1]
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
      when :ivar, :lvar, :const
        exp[1]
      when :true, :false
        exp[0]
      when :lit
        exp[1]
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
      if sexp? item[1]
        item[2] == :new and item[1].node_type == :const and item[1][1] == klass
      else
        item[2] == :new and item[1] == klass
      end
    else
      false
    end
  end
end
