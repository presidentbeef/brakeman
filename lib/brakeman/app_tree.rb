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
        init_options[:skip_files] = regex_for_paths(options[:skip_files])
      end

      if options[:only_files]
        init_options[:only_files] = regex_for_paths(options[:only_files])
      end
      init_options[:additional_libs_path] = options[:additional_libs_path]
      init_options[:engines_path] = options[:engines_path]
      new(root, init_options)
    end

    # Accepts an array of filenames and paths with the following format and
    # returns a Regexp to match them:
    #   * "path1/file1.rb" - Matches a specific filename in the project directory.
    #   * "path1/" - Matches any path that conatains "path1" in the project directory.
    #   * "/path1/ - Matches any path that is rooted at "path1" in the project directory.
    #
    def self.regex_for_paths(paths)
      path_regexes = paths.map do |f|
        # If path ends in a file separator then we assume it is a path rather
        # than a filename.
        if f.end_with?(File::SEPARATOR)
          # If path starts with a file separator then we assume that they
          # want the project relative path to start with this path prefix.
          if f.start_with?(File::SEPARATOR)
            "\\A#{Regexp.escape f}"
          # If it ends in a file separator, but does not begin with a file
          # separator then we assume the path can match any path component in
          # the project.
          else
            Regexp.escape f
          end
        else
          "#{Regexp.escape f}\\z"
        end
      end
      Regexp.new("(?:" << path_regexes.join("|") << ")")
    end
    private_class_method(:regex_for_paths)

    def initialize(root, init_options = {})
      @root = root
      @project_root_path = Pathname.new(@root)
      @skip_files = init_options[:skip_files]
      @only_files = init_options[:only_files]
      @additional_libs_path = init_options[:additional_libs_path] || []
      @engines_path = init_options[:engines_path] || []
      @absolute_engines_path = @engines_path.select { |path| path.start_with?(File::SEPARATOR) }
      @relative_engines_path = @engines_path - @absolute_engines_path
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
      File.exist?(File.join(@root, path))
    end

    # This is a pair for #read_path. Again, would like to kill these
    def path_exists?(path)
      File.exist?(path)
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
      !glob_files("app/views/layouts", name, "{.erb, .haml, .slim}").empty?
    end

    def lib_paths
      @lib_files ||= find_paths("lib").reject { |path| path.include? "/generators/" or path.include? "lib/tasks/" } +
                     find_additional_lib_paths +
                     find_helper_paths
    end

  private

    def find_helper_paths
      find_paths "app/helpers"
    end

    def find_additional_lib_paths
      @additional_libs_path.collect{ |path| find_paths path }.flatten
    end

    def find_paths(directory, extensions = ".rb")
      select_files(glob_files(directory, "*", extensions).sort)
    end

    def glob_files(directory, name, extensions = ".rb")
      abs_engines = @absolute_engines_path.to_a.join(",")
      rel_engines = @relative_engines_path.empty? ? "" : "{#{@relative_engines_path.to_a.join("/,")},}/"
      pattern = "{#{@root},#{abs_engines}}" + "/#{rel_engines}#{directory}/**/#{name}#{extensions}"

      Dir.glob(pattern)
    end

    def select_files(paths)
      paths = select_only_files(paths)
      reject_skipped_files(paths)
    end

    def select_only_files(paths)
      return paths unless @only_files

      paths.select do |path|
        match_path @only_files, path
      end
    end

    def reject_skipped_files(paths)
      return paths unless @skip_files

      paths.reject do |path|
        match_path @skip_files, path
      end
    end

    def match_path files, path
      absolute_path = Pathname.new(path)
      # relative root never has a leading separator. But, we use a leading
      # separator in a @skip_files entry to imply that a directory is
      # "absolute" with respect to the project directory.
      project_relative_path = File.join(
        File::SEPARATOR,
        absolute_path.relative_path_from(@project_root_path).to_s
      )

      files.match(project_relative_path)
    end
  end
end
