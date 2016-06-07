require 'brakeman/processors/output_processor'

module Brakeman
  class Constant
    attr_reader :name, :name_array, :file, :value

    def initialize name, value = nil, context = nil 
      set_name name, context
      @value = value
      @context = context

      if @context
        @file = @context[:file]
      end
    end

    def line
      if @value.is_a? Sexp
        @value.line
      end
    end

    def set_name name, context
      @name = name
      @name_array = Constants.constant_as_array(name)
    end

    def match? name
      if name == @name
        return true
      elsif name.is_a? Sexp and name.node_type == :const and name.value == @name
        return true
      elsif name.is_a? Symbol and name.value == @name
        return true
      elsif name.class == Array
        name == @name_array or
          @name_array.reverse.zip(name.reverse).reduce(true) { |m, a| a[1] ? a[0] == a[1] && m : m }
      else
        false
      end
    end
  end

  class Constants
    include Brakeman::Util

    def initialize
      @constants = Hash.new { |h, k| h[k] = [] }
    end

    def size
      @constants.length
    end

    def [] exp
      return unless constant? exp
      match = find_constant exp

      if match
        match.value
      else
        nil
      end
    end

    def find_constant exp
      base_name = Constants.get_constant_base_name(exp)

      if @constants.key? base_name
        @constants[base_name].find do |c|
          if c.match? exp
            return c
          end
        end

        name_array = Constants.constant_as_array(exp)

        # Avoid losing info about dynamic constant values
        return unless name_array.all? { |n| constant? n or n.is_a? Symbol }

        @constants[base_name].find do |c|
          if c.match? name_array
            return c
          end
        end
      end

      nil
    end

    def add name, value, context = nil
      if call? value and value.method == :freeze
        value = value.target
      end

      base_name = Constants.get_constant_base_name(name)
      @constants[base_name] << Constant.new(name, value, context)
    end

    LITERALS = [:lit, :false, :str, :true, :array, :hash]
    def literal? exp
      exp.is_a? Sexp and LITERALS.include? exp.node_type
    end

    def get_literal name
      if x = self[name] and literal? x
        x
      else
        nil
      end
    end

    def each
      @constants.each do |name, values|
        values.each do |constant|
          yield constant
        end
      end
    end

    def self.constant_as_array exp
      res = []
      while exp
        if exp.is_a? Sexp
          case exp.node_type
          when :const
            res << exp.value
            exp = nil
          when :colon3
            res << exp.value << :""
            exp = nil
          when :colon2
            res << exp.last
            exp = exp[1]
          else
            res << exp
            exp = nil
          end
        else
          res << exp
          exp = nil
        end
      end

      res.reverse!
      res
    end

    def self.get_constant_base_name exp
      return exp unless exp.is_a? Sexp

      case exp.node_type
      when :const, :colon3
        exp.value
      when :colon2
        exp.last
      else
        exp
      end
    end
  end
end
