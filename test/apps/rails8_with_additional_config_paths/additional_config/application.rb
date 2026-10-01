module AdditionalConfig
  module Application
    extend ActiveSupport::Concern

    included do
      # Initialize configuration defaults for originally generated Rails version.
      config.load_defaults 8.0

      # Please, add to the `ignore` list any other `lib` subdirectories that do
      # not contain `.rb` files, or that should not be reloaded or eager loaded.
      # Common ones are `templates`, `generators`, or `middleware`, for example.
      config.autoload_lib(ignore: %w[assets tasks])

      # Configuration for the application, engines, and railties goes here.
      #
      # These settings can be overridden in specific environments using the files
      # in config/environments, which are processed later.
      #
      # config.time_zone = "Central Time (US & Canada)"
      # config.eager_load_paths << Rails.root.join("extras")

      # Don't generate system test files.
      config.generators.system_tests = nil
    end
  end
end