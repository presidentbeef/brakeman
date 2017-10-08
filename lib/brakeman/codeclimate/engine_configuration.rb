require 'pathname'

module Brakeman
  module Codeclimate
    class EngineConfiguration

      def initialize(engine_config = {})
        @engine_config = engine_config
      end

      def options
        default_options.merge(configured_options)
      end

      private

      attr_reader :engine_config

      def default_options
        @default_options = {
          :output_format => :codeclimate,
          :quiet => true,
          :pager => false,
          :app_path => Dir.pwd
        }
        if system("test -w /dev/stdout")
          @default_options[:output_files] = ["/dev/stdout"]
        end
        @default_options
      end

      def configured_options
        @configured_options = {}
        # ATM this gets parsed as a string instead of bool: "config":{ "debug":"true" }
        if brakeman_configuration["debug"] && brakeman_configuration["debug"].to_s.downcase == "true"
          @configured_options[:debug] = true
          @configured_options[:report_progress] = false
        end

        if engine_config["include_paths"]
          @configured_options[:only_files] = engine_config["include_paths"].compact
        end

        if brakeman_configuration["app_path"]
          @configured_options[:path_prefix] = brakeman_configuration["app_path"]
          path = Pathname.new(Dir.pwd) + brakeman_configuration["app_path"]
          @configured_options[:app_path] = path.to_s
        end
        @configured_options
      end

      def brakeman_configuration
        if engine_config["config"]
          engine_config["config"]
        else
          {}
        end
      end

    end
  end
end
