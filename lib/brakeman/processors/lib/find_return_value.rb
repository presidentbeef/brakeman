require 'brakeman/processors/alias_processor'

#Attempts to determine the return value of a method.
#
#Preferred usage:
#
#  Brakeman::FindReturnValue.return_value exp
class Brakeman::FindReturnValue
  include Brakeman::Util

  #Returns a guess at the return value of a given method or other block of code.
  #
  #If multiple return values are possible, returns all values in an :or Sexp.
  def self.return_value exp, env = nil
    self.new.get_return_value exp, env
  end

  def initialize
    @return_values = []
  end

  #Find return value of Sexp. Takes an optional starting environment.
  def get_return_value exp, env = nil
    process_method exp, env
    value = make_return_value
    value.original_line(exp.line)
    value
  end

  #Process method (or, actually, any Sexp) for return value.
  def process_method exp, env = nil
    exp = Brakeman::AliasProcessor.new.process_safely exp, env

    find_explicit_return_values exp

    if node_type? exp, :methdef, :selfdef, :defn, :defs
      if exp[-1]
        @return_values << last_value(exp[-1])
      else
        Brakeman.debug "FindReturnValue: Empty method? #{exp.inspect}"
      end
    elsif exp
      @return_values << last_value(exp)
    else
       Brakeman.debug "FindReturnValue: Given something strange? #{exp.inspect}"
    end

    exp
  end

  #Searches expression for return statements.
  def find_explicit_return_values exp
    todo = [exp]

    until todo.empty?
      current = todo.shift

      if node_type? current, :return
        @return_values << current[1] unless current[1].nil?
      elsif sexp? current
        todo = current[1..-1].concat todo
      end
    end
  end

  #Determines the "last value" of an expression.
  def last_value exp
    case exp.node_type
    when :rlist, :block, :scope
      last_value exp[-1]
    when :if
      if exp[2].nil?
        last_value exp[3]
      elsif exp[3].nil?
        last_value exp[2]
      else
        true_branch = last_value exp[2]
        false_branch = last_value exp[3]

        if true_branch and false_branch
          value = Sexp.new(:or, last_value(exp[2]), last_value(exp[3]))
          value.original_line(value[2].line)
          value
        else
          true_branch or false_branch
        end
      end
    when :return
      exp[1]
    else
      exp.original_line(exp.line) unless exp.original_line
      exp
    end
  end

  #Turns the array of return values into an :or Sexp
  def make_return_value
    @return_values.compact!
    @return_values.uniq!

    if @return_values.empty?
      Sexp.new(:nil)
    elsif @return_values.length == 1
      @return_values[0]
    else
      @return_values.reduce do |value, sexp|
        Sexp.new(:or, value, sexp)
      end
    end
  end
end
