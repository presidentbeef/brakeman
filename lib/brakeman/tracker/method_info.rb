require 'brakeman/util'

module Brakeman
  class MethodInfo
    include Brakeman::Util

    attr_reader :name, :src, :file, :type

    def initialize name, src, file
      @name = name
      @src = src
      @file = file
      @simple_method = nil
      @return_value = nil
      @type = case src.node_type
              when :defn
                :instance
              when :defs
                :class
              else
                raise "Expected sexp type: #{src.node_type}"
              end
    end

    # To support legacy code that expected a Hash
    def [] attr
      self.send(attr)
    end

    def very_simple_method?
      return @simple_method == :very unless @simple_method.nil?

      # Very simple methods have one (simple) expression in the body and
      # no arguments
      if src.formal_args.length == 1 # no args
        body = src.body
        if body.length == 1 # single expression in body
          value = body.first

          if simple_literal? value or
              (array? value and all_literals? value)

            @return_value = value
            @simple_method = :very
          end
        end
      end

      @simple_method ||= false
    end

    def return_value env = nil
      if very_simple_method?
        return @return_value
      else
        nil
      end
    end
  end
end
