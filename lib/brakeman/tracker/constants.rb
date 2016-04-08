require 'brakeman/processors/output_processor'

module Brakeman
  class Constant
    attr_reader :name, :file

    def initialize name, value = nil, context = nil 
      set_name name, context
      @values = [ value ]
      @context = context

      if @context
        @file = @context[:file]
      end
    end

    def line
      if @values.first.is_a? Sexp
        @values.first.line
      end
    end

    def set_name name, context
      @name = Constants.constant_as_array(name)
    end

    def match? name
      @name.reverse.zip(name.reverse).reduce(true) { |m, a| a[1] ? a[0] == a[1] && m : m }
    end

    def value
      @values.reverse.reduce do |m, v|
        Sexp.new(:or, v, m)
      end
    end

    def add_value exp
      unless @values.include? exp
        @values << exp
      end
    end
  end

  class Constants
    include Brakeman::Util

    def initialize
      @constants = []
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
      name = Constants.constant_as_array(exp)
      @constants.find do |c|
        c.match? name
      end
    end

    def add name, value, context = nil
      if existing = self.find_constant(name)
        existing.add_value value
      else
        @constants << Constant.new(name, value, context)
      end
    end

    def get_literal name
      if x = self[name] and [:lit, :false, :str, :true, :array, :hash].include? x.node_type
        x
      else
        nil
      end
    end

    def each &block
      @constants.each &block
    end

    def self.constant_as_array exp
      get_constant_name(exp).split('::')
    end

    def self.get_constant_name exp
      if exp.is_a? Sexp
        Brakeman::OutputProcessor.new.format(exp)
      else
        exp.to_s
      end
    end
  end
end
