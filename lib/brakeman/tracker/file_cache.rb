module Brakeman
  class FileCache
    def initialize
      @file_list = {
        controller: {},
        initializer: {},
        lib: {},
        model: {},
        template: {},
      }
    end

    def controllers
      @file_list[:controller]
    end

    def initializers
      @file_list[:initializer]
    end

    def libs
      @file_list[:lib]
    end

    def models
      @file_list[:model]
    end

    def templates
      @file_list[:template]
    end

    def add_file(astfile, type)
      raise "Unknown type: #{type}" unless valid_type? type

      @file_list[type][astfile.path] = astfile
    end

    def valid_type?(type)
      @file_list.key? type
    end
  end
end
