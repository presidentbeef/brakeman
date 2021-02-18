require 'brakeman/util'

module Brakeman
  class MethodInfo
    include Brakeman::Util

    attr_reader :name, :src, :owner, :file, :type

    def initialize name, src, owner, file
      @name = name
      @src = src
      @owner = owner
      @file = file
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
  end
end
