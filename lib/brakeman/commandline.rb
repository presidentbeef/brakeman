require 'brakeman/options'

module Brakeman
  class Commandline
    class << self
      def start options = nil, app_path = "."

        unless options
          options, app_path = parse_options ARGV
        end

        run options, app_path
      end

      def parse_options argv
        begin
          options, _ = Brakeman::Options.parse! argv
        rescue OptionParser::ParseError => e
          $stderr.puts e.message
          $stderr.puts "Please see `brakeman --help` for valid options"
          quit(-1)
        end

        app_path = argv[-1] if argv[-1]

        return options, app_path
      end

      def quit exit_code = 0, message = nil
        warn message if message
        exit exit_code
      end

      def run options, default_app_path = "."
        set_interrupt_handler options
        early_exit_options options
        set_options options, default_app_path
        check_latest if options[:ensure_latest]
        run_report options
      end

      def check_latest
        if error = Brakeman.ensure_latest
          quit Brakeman::Not_Latest_Version_Exit_Code, error
        end
      end

      def compare_results options
        require 'json'
        vulns = Brakeman.compare options.merge(:quiet => options[:quiet])

        if options[:comparison_output_file]
          File.open options[:comparison_output_file], "w" do |f|
            f.puts JSON.pretty_generate(vulns)
          end

          Brakeman.notify "Comparison saved in '#{options[:comparison_output_file]}'"
        else
          puts JSON.pretty_generate(vulns)
        end

        if options[:exit_on_warn] && vulns[:new].count > 0
          quit Brakeman::Warnings_Found_Exit_Code
        end
      end

      def regular_report options
        tracker = run_brakeman options 

        if options[:exit_on_warn] and not tracker.filtered_warnings.empty?
          quit Brakeman::Warnings_Found_Exit_Code
        end

        if options[:exit_on_error] and tracker.errors.any?
          quit Brakeman::Errors_Found_Exit_Code
        end
      end

      def run_brakeman options
        Brakeman.run options.merge(:print_report => true, :quiet => options[:quiet])
      end

      def run_report options
        begin
          if options[:previous_results_json]
            compare_results options
          else
            regular_report options
          end
        rescue Brakeman::NoApplication => e
          quit Brakeman::No_App_Found_Exit_Code, e.message
        rescue Brakeman::MissingChecksError => e
          quit Brakeman::Missing_Checks_Exit_Code, e.message
        end
      end

      def set_options options, default_app_path = "."
        unless options[:app_path]
          options[:app_path] = default_app_path
        end

        if options[:quiet].nil?
          options[:quiet] = :command_line
        end

        options
      end

      def early_exit_options options
        if options[:list_checks] or options[:list_optional_checks]
          Brakeman.list_checks options
          quit
        elsif options[:create_config]
          Brakeman.dump_config options
          quit
        elsif options[:show_help]
          puts Brakeman::Options.create_option_parser({})
          quit
        elsif options[:show_version]
          require 'brakeman/version'
          puts "brakeman #{Brakeman::Version}"
          quit
        end
      end

      def set_interrupt_handler options
        trap("INT") do
          warn "\nInterrupted - exiting."

          if options[:debug]
            warn caller
          end

          exit!
        end
      end
    end
  end
end
