require 'pathname'

module Brakeman
  class FilePath
    attr_reader :absolute, :relative
    @cache = {}

    def self.from_tracker tracker, path
      return path if path.is_a? Brakeman::FilePath
      self.from_app_tree tracker.app_tree, path
    end

    def self.from_app_tree app_tree, path
      return path if path.is_a? Brakeman::FilePath

      absolute = app_tree.expand_path(path).freeze

      if fp = @cache[absolute]
        puts "CACHED!"
        return fp 
      end

      relative = app_tree.relative_path(path).freeze

      self.new(absolute, relative).tap { |fp| @cache[absolute] = fp }
    end

    def initialize absolute_path, relative_path
      @absolute = absolute_path
      @relative = relative_path
    end

    def <=> rhs
      raise ArgumentError unless rhs.is_a? Brakeman::FilePath
      self.relative <=> rhs.relative
    end

    def == rhs
      return false unless rhs.is_a? Brakeman::FilePath

      self.absolute == rhs.absolute
    end

    def to_str
      self.absolute
    end

    def to_s
      self.to_str
    end
  end
end
