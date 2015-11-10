require 'pathname'

module Brakeman
  class AppTree
    VIEW_EXTENSIONS = %w[html.erb html.haml rhtml js.erb html.slim].join(",")

    attr_reader :root

    def self.from_options(options)
      root = File.expand_path options[:app_path]

      # Convert files into Regexp for matching
      init_options = {}
      if options[:skip_files]
        skip_files_escaped = options[:skip_files].map do |f|
          # If path ends in a file separator then we assume it is a path rather
          # than a filename.
          if f.end_with?(File::SEPARATOR)
            # If path starts with a file separator then we assume that they
            # want the project relative path to start with this path.
            if f.start_with?(File::SEPARATOR)
              "\\A#{Regexp.escape f}"
            # If it ends in a file separator, but does not begin with a file
            # separator then we assume the path can match any part of the project
            # relative path.
            else
              Regexp.escape f
            end
          else
            "#{Regexp.escape f}\\z"
          end
        end
        init_options[:skip_files] = Regexp.new("(?:" << skip_files_escaped.join("|") << ")")
      end

      if options[:only_files]
        only_files_escaped = options[:only_files].map do |f|
          # If it ends in a file separator then we assume it is a path rather
          # than a filename.
          if f.end_with?(File::SEPARATOR)
            # If it starts with a file separator then we assume that they
            # want the project relative path to start with this path
            if f.start_with?(File::SEPARATOR)
              "\\A#{Regexp.escape f}"
            # If it ends in a file separator, but does not begin with a file
            # separator then we assume the path can match any part of the project
            # relative path.
            else
              Regexp.escape f
            end
          else
            "#{Regexp.escape f}\\z"
          end
        end
        init_options[:only_files] = Regexp.new("(?:" << only_files_escaped.join("|") << ")")
      end
      init_options[:additional_libs_path] = options[:additional_libs_path]
      new(root, init_options)
    end

    def initialize(root, init_options = {})
      @root = root
      @skip_files = init_options[:skip_files]
      @only_files = init_options[:only_files]
      @additional_libs_path = init_options[:additional_libs_path] || []
    end

    def expand_path(path)
      File.expand_path(path, @root)
    end

    def read(path)
      File.read(File.join(@root, path))
    end

    # This variation requires full paths instead of paths based
    # off the project root. I'd prefer to get all the code outside
    # of AppTree using project-root based paths (e.g. app/models/user.rb)
    # instead of full paths, but I suspect it's an incompatible change.
    def read_path(path)
      File.read(path)
    end

    def exists?(path)
      File.exists?(File.join(@root, path))
    end

    # This is a pair for #read_path. Again, would like to kill these
    def path_exists?(path)
      File.exists?(path)
    end

    def initializer_paths
      @initializer_paths ||= find_paths("config/initializers")
    end

    def controller_paths
      @controller_paths ||= find_paths("app/**/controllers")
    end

    def model_paths
      @model_paths ||= find_paths("app/**/models")
    end

    def template_paths
      @template_paths ||= find_paths("app/**/views", "*.{#{VIEW_EXTENSIONS}}")
    end

    def layout_exists?(name)
      pattern = "#{@root}/{engines/*/,}app/views/layouts/#{name}.html.{erb,haml,slim}"
      !Dir.glob(pattern).empty?
    end

    def lib_paths
      @lib_files ||= find_paths("lib").reject { |path| path.include? "/generators/" or path.include? "lib/tasks/" } +
                     find_additional_lib_paths
    end

  private

    def find_additional_lib_paths
      @additional_libs_path.collect{ |path| find_paths path }.flatten
    end

    def find_paths(directory, extensions = "*.rb")
      pattern = @root + "/{engines/*/,}#{directory}/**/#{extensions}"

      select_files(Dir.glob(pattern).sort)
    end

    def select_files(paths)
      paths = select_only_files(paths)
      reject_skipped_files(paths)
    end

    def select_only_files(paths)
      return paths unless @only_files
      project_root  = Pathname.new(@root)
      paths.select do |path|
        absolute_path = Pathname.new(path)
        # relative root never has a leading separator. But, we use a leading
        # separator in a @skip_files entry to imply that a directory is
        # "absolute" with respect to the project directory.
        project_relative_path = File::SEPARATOR + absolute_path.relative_path_from(project_root).to_s
        @only_files.match(project_relative_path)
      end
    end

    def reject_skipped_files(paths)
      return paths unless @skip_files
      project_root  = Pathname.new(@root)
      paths.reject do |path|
        absolute_path = Pathname.new(path)
        # relative root never has a leading separator. But, we use a leading
        # separator in a @skip_files entry to imply that a directory is
        # "absolute" with respect to the project directory.
        project_relative_path = File::SEPARATOR + absolute_path.relative_path_from(project_root).to_s
        @skip_files.match(project_relative_path)
      end
    end

  end
end
