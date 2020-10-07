require 'set'

module Brakeman
  # Represents a class name, including variations with different scopes.
  class ClassName
    attr_reader :names

    def initialize name
      @names = [name.to_sym]

      unless name.to_s.start_with? "::"
        name.to_s.split('::').reverse.inject do |full, current|
          @names << full.to_sym
          current << "::" << full
        end
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

  # Holds a collection of classes indexed by class name.
  class ClassCollection
    def initialize
      @class_index = {}
      @classes = []
    end

    # Add class to collection by name.
    def []= name, klass
      if name.is_a? ClassName
        @class_index[name.key] = klass
      else
        @class_index[name.to_sym] = klass
      end

      @classes << klass
    end

    # Look up class by name.
    # If `strict` is `true`, only the indexed name will be used.
    #
    # Otherwise, if the name is not in the index, each class
    # will attempt to match the name in a more general way.
    def [] name, strict = true
      return nil if name.nil? # TODO why are we looking up nil class names?

      if name.is_a? ClassName
        if klass = @class_index[name.key]
          return klass
        elsif strict
          return nil
        end
      elsif klass = @class_index[name]
        return klass
      elsif strict
        return nil
      end

      @classes.each do |klass|
        return klass if klass.name == name
      end

      nil
    end

    # Add class by name.
    def << klass
      self[klass.name] = klass
    end

    # Delete class by name.
    def delete name
      deleted = @class_index.delete name
      @classes.delete(deleted)

      deleted # To match Hash behavior
    end

    # Iterate over all classes and delete when the block returns true.
    def delete_if &block
      @classes.delete_if do |klass|
        if yield(klass)
          @class_index.delete klass.name
          true
        end
      end
    end

    # Iterate over each (name, class) pair.
    def each &block
      @class_index.each &block
    end

    # Iterate over each class.
    def each_class &block
      @class_index.each_value &block
    end

    # Return true if the collection has any classes.
    def any?
      raise ArgumentError if block_given?

      !self.empty?
    end

    # Return true if the collection is empty.
    def empty?
      @classes.empty?
    end

    # Returns true if the collection contains the given class name.
    #
    # *Fuzzy* match on class name.
    def include? class_name
      !!self[class_name, false]
    end

    # Return class names in index.
    def keys
      @class_index.keys
    end

    # Return number of classes in collection.
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
