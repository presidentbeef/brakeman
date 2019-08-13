require 'set'

module Brakeman
  class ClassName
    def initialize name
      @names = [name.to_sym]
    end

    def key_name
      @names.first
    end
  end

  class ClassCollection
    def initialize
      @class_index = {}
      @classes = []
    end

    def []= name, klass
      @class_index[name.to_sym] = klass
      @classes << klass
    end

    def [] name
      if klass = @class_index[name]
        return klass
      end

      @classes.each do |klass|
        return klass if klass.name == klass
      end

      nil
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
