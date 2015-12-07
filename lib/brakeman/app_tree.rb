module Brakeman
  class AppTree
    VIEW_EXTENSIONS = %w[html.erb html.haml rhtml js.erb html.slim].join(",")

    attr_reader :root

    def self.from_options(options)
      root = File.expand_path options[:app_path]

      # Convert files into Regexp for matching
      init_options = {}
      if options[:skip_files]
        init_options[:skip_files] = Regexp.new("(?:" << options[:skip_files].map { |f| Regexp.escape f }.join("|") << ")$")
      end
      if options[:only_files]
        init_options[:only_files] = Regexp.new("(?:" << options[:only_files].map { |f| Regexp.escape f }.join("|") << ")")
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
      paths.select { |f| @only_files.match f }
    end

    def reject_skipped_files(paths)
      return paths unless @skip_files
      paths.reject { |f| @skip_files.match f }
    end

  end
end
