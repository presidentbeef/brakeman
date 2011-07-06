OPTIONS = {}

module Brakeman

  #loads the saved options and runs the scan
  def self.main(options_from_cli={}, cli_mode=false)
    #restore the config from file, or load the defaults
    restore_config(options_from_cli)

    #Load scanner
    begin
      require 'scanner'
    rescue LoadError
      abort "Cannot find lib/ directory."
    end

    #Start scanning
    scanner = Scanner.new OPTIONS[:app_path]

    warn "Processing application in #{OPTIONS[:app_path]}"
    tracker = scanner.process

    warn "Running checks..."
    tracker.run_checks

    warn "Generating report..."
    if OPTIONS[:output_file]
      File.open OPTIONS[:output_file], "w" do |f|
        f.puts tracker.report.send(OPTIONS[:output_format])
      end
      warn "Report saved in '#{OPTIONS[:output_file]}'"
    else
      puts tracker.report.send(OPTIONS[:output_format])
    end

    #if warnings have been found, exit with a non-zero exit code (for Continuous
    #Integration)
    exit tracker.checks.warnings.length if cli_mode
    return tracker.checks.warnings.length
  end

  private

  #Load configuation file, and fills in the blanks with the default values
  def self.restore_config(options={})
    [File.expand_path(options[:config_file].to_s),
      File.expand_path("./config.yaml"),
      File.expand_path("~/.brakeman/config.yaml"),
      File.expand_path("/etc/brakeman/config.yaml"),
      "#{File.expand_path(File.dirname(__FILE__))}/../lib/config.yaml"].each do |f|

      if File.exist? f and not File.directory? f
        warn "[Notice] Using configuration in #{f}" unless options[:quiet]
        OPTIONS.merge! YAML.load_file f
        OPTIONS.merge! options
        OPTIONS.each do |k,v|
          if v.is_a? Array
            OPTIONS[k] = Set.new v
          end
        end
        break
      end
    end

    OPTIONS.merge! options

    #List available checks and exits
    list_checks if OPTIONS[:list_checks]

    #Set defaults just in case
    { :skip_checks => Set.new, 
      :check_arguments => true, 
      :safe_methods => Set.new,
      :min_confidence => 2,
      :combine_locations => true,
      :collapse_mass_assignment => true,
      :ignore_redirect_to_model => true,
      :ignore_model_output => false,
      :message_limit => 100,
      :html_style => "#{File.expand_path(File.dirname(__FILE__))}/../lib/format/style.css" 
    }.each do |k,v|
      OPTIONS[k] = v if OPTIONS[k].nil?
    end

    #Set output format
    if OPTIONS[:output_format]
      case OPTIONS[:output_format]
      when :html, :to_html
        OPTIONS[:output_format] = :to_html
      when :csv, :to_csv
        OPTIONS[:output_format] = :to_csv
      when :pdf, :to_pdf
        OPTIONS[:output_format] = :to_pdf
      when :tabs, :to_tabs
        OPTIONS[:output_format] = :to_tabs
      else
        OPTIONS[:output_format] = :to_s
      end
    else
      case OPTIONS[:output_file]
      when /\.html$/i
        OPTIONS[:output_format] = :to_html
      when /\.csv$/i
        OPTIONS[:output_format] = :to_csv
      when /\.pdf$/i
        OPTIONS[:output_format] = :to_pdf
      when /\.tabs$/i
        OPTIONS[:output_format] = :to_tabs
      else
        OPTIONS[:output_format] = :to_s
      end
    end

    #Output configuration if requested
    if OPTIONS[:create_config]

      if OPTIONS[:create_config].is_a? String
        file = OPTIONS[:create_config]
      else
        file = nil
      end

      OPTIONS.delete :create_config

      OPTIONS.each do |k,v|
        if v.is_a? Set
          OPTIONS[k] = v.to_a
        end
      end

      if file
        File.open file, "w" do |f|
          YAML.dump OPTIONS, f
        end
        puts "Output configuration to #{file}"
      else
        puts YAML.dump(OPTIONS)
      end
      exit
    end

    #Check application path
    unless OPTIONS[:app_path]
      if ARGV[-1].nil?
        OPTIONS[:app_path] = File.expand_path "."
      else
        OPTIONS[:app_path] = File.expand_path ARGV[-1]
      end
    end

    app_path = OPTIONS[:app_path]

    abort("Please supply the path to a Rails application.") unless app_path and File.exist? File.join(app_path, "app")

    warn "[Notice] Using Ruby #{RUBY_VERSION}. Please make sure this matches the one used to run your Rails application."

    if File.exist? app_path + "/script/rails"
      OPTIONS[:rails3] = true
      warn "[Notice] Detected Rails 3 application. Enabling experimental Rails 3 support." 
    end
  end

end


begin
    #Declare rake tasks
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load "tasks/brakeman_tasks.rake"
      end
    end
rescue NameError:
    #This happens when not running through rake
end
