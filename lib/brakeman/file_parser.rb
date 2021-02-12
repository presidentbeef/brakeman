require 'parallel'

module Brakeman
  ASTFile = Struct.new(:path, :ast)

  # This class handles reading and parsing files.
  class FileParser
    attr_reader :file_list, :errors

    def initialize app_tree, timeout
      @app_tree = app_tree
      @timeout = timeout
      @file_list = []
      @errors = []
    end

    def parse_files list
      @file_list = Parallel.map(list) do |file_name|
        file_path = @app_tree.file_path(file_name)
        contents = file_path.read

        if ast = parse_ruby(contents, file_path.relative)
          ASTFile.new(file_name, ast)
        else
          nil
        end
      end.compact
    end

    def read_files list
      list.each do |path|
        file = @app_tree.file_path(path)

        result = yield file, file.read

        if result
          @file_list << result
        end
      end
    end

    # _path_ can be a string or a Brakeman::FilePath
    def parse_ruby input, path
      if path.is_a? Brakeman::FilePath
        path = path.relative
      end

      begin
        Brakeman.debug "Parsing #{path}"
        RubyParser.new.parse input, path, @timeout
      rescue Racc::ParseError => e
        error e.exception(e.message + "\nCould not parse #{path}")
      rescue Timeout::Error => e
        error Exception.new("Parsing #{path} took too long (> #{@timeout} seconds). Try increasing the limit with --parser-timeout")
      rescue => e
        error e.exception(e.message + "\nWhile processing #{path}")
      end
    end

    def error exception
      @errors << exception
      nil
    end
  end
end
