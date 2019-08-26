require 'set'

module Brakeman
  class ClassName
    attr_reader :names

    def initialize name
      @names = [name.to_sym]

      name.to_s.split('::').reverse.inject do |full, current|
        @names << full.to_sym
        current << "::" << full
      end
    end

    def key
      @names.first
    end

    def include? name
      if name.is_a? ClassName
        (@names & name.names).any?
      else
        @names.include? name
      end
    end

    def == name
      return true if self.object_id == name.object_id

      self.include? name
    end

    def to_sym
      self.key.to_sym
    end

    def to_s
      self.key.to_s
    end

    def inspect
      self.to_sym.inspect
    end
  end

  class ClassCollection
    def initialize
      @class_index = {}
      @classes = []
    end

    def []= name, klass
      if name.is_a? ClassName
        @class_index[name.key] = klass
      else
        @class_index[name.to_sym] = klass
      end

      @classes << klass
    end

    def [] name
      return nil if name.nil? # TODO why are we looking up nil class names?

      if name.is_a? ClassName
        if klass = @class_index[name.key]
          return klass
        end

        @classes.each do |klass|
          klass.name == name
        end
      elsif klass = @class_index[name]
        return klass
      end

      @classes.each do |klass|
        return klass if klass.name == name
      end

      nil
    end

    def << klass
      self[klass.name] = klass
    end

    def delete name
      deleted = @class_index.delete name
      @classes.delete(deleted)

      deleted # To match Hash behavior
    end

    def delete_if &block
      @classes.delete_if do |klass|
        if yield(klass)
          @class_index.delete klass.name
          true
        end
      end
    end

    def each &block
      @class_index.each &block
    end

    def each_class &block
      @class_index.each_value &block
    end

    def any?
      raise ArgumentError if block_given?

      !self.empty?
    end

    def empty?
      @classes.empty?
    end

    def include? class_name
      !!self[class_name]
    end

    def keys
      @class_index.keys
    end

    def length
      @classes.length
    end

    def select &block
      @class_index.select &block
    end

    def sort_by &block
      @class_index.sort_by &block
    end
  end
end
