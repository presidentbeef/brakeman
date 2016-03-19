require 'brakeman/processors/output_processor'

module Brakeman
  class Constant
    def initialize name, value = nil, context = nil 
      set_name name, context
      @values = [ value ]
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
  end

  class Constants
    include Brakeman::Util

    def initialize
      @constants = []
    end

    def [] exp
      return unless constant? exp
      name = Constants.constant_as_array(exp)
      match = @constants.find do |c|
        c.match? name
      end

      if match
        match.value
      else
        nil
      end
    end

    def add name, value, context
      @constants << Constant.new(name, value, context)
    end

    def self.constant_as_array exp
      get_constant_name(exp).split('::')
    end

    def self.get_constant_name exp
      if exp.is_a? Symbol
        exp.to_s
      else
        Brakeman::OutputProcessor.new.format(exp)
      end
    end
  end
end
