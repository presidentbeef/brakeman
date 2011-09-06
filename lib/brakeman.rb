require 'yaml'

OPTIONS = {}

module Brakeman
  def self.run options
    if options[:list_checks]
      list_checks
      exit
    end

    if options[:create_config]
      dump_config options
      exit
    end

    scan set_options(options)
  end

  private

  def self.set_options options
    options = load_options(options[:config_file]).merge! options
    options = get_defaults.merge! options
    options[:output_format] = get_output_format options

    #Check application path
    unless options[:app_path]
      if ARGV[-1].nil?
        options[:app_path] = File.expand_path "."
      else
        options[:app_path] = File.expand_path ARGV[-1]
      end
    end

    app_path = options[:app_path]

    abort("Please supply the path to a Rails application.") unless app_path and File.exist? app_path + "/app"

    if File.exist? app_path + "/script/rails"
      options[:rails3] = true
      warn "[Notice] Detected Rails 3 application. Enabling experimental Rails 3 support." 
    end

    options
  end

  def self.load_options config_file
    config_file ||= ""

    #Load configuation file
    [File.expand_path(config_file),
      File.expand_path("./config.yaml"),
      File.expand_path("~/.brakeman/config.yaml"),
      File.expand_path("/etc/brakeman/config.yaml"),
      "#{File.expand_path(File.dirname(__FILE__))}/../lib/config.yaml"].each do |f|

      if File.exist? f and not File.directory? f
        warn "[Notice] Using configuration in #{f}" unless options[:quiet]
        options = YAML.load_file f
        options.each do |k,v|
          if v.is_a? Array
            options[k] = Set.new v
          end
        end

        return options
      end
      end

    return {}
  end

  def self.get_defaults
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
    }
  end

  def self.get_output_format options
    #Set output format
    if options[:output_format]
      case options[:output_format]
      when :html, :to_html
        :to_html
      when :csv, :to_csv
        :to_csv
      when :pdf, :to_pdf
        :to_pdf
      when :tabs, :to_tabs
        :to_tabs
      else
        :to_s
      end
    else
      case options[:output_file]
      when /\.html$/i
        :to_html
      when /\.csv$/i
        :to_csv
      when /\.pdf$/i
        :to_pdf
      when /\.tabs$/i
        :to_tabs
      else
        :to_s
      end
    end
  end

  def self.list_checks
    require 'scanner'
    $stderr.puts "Available Checks:"
    $stderr.puts "-" * 30
    $stderr.puts Checks.checks.map { |c| c.to_s }.sort.join "\n"
  end

  def self.dump_config options
    if options[:create_config].is_a? String
      file = options[:create_config]
    else
      file = nil
    end

    options.delete :create_config

    options.each do |k,v|
      if v.is_a? Set
        options[k] = v.to_a
      end
    end

    if file
      File.open file, "w" do |f|
        YAML.dump options, f
      end
      puts "Output configuration to #{file}"
    else
      puts YAML.dump(options)
    end
    exit
  end

  def self.scan options
    OPTIONS.clear
    OPTIONS.merge! options

    #Load scanner
    warn "Loading scanner..."

    begin
      require 'scanner'
    rescue LoadError
      abort "Cannot find lib/ directory."
    end

    #Start scanning
    scanner = Scanner.new options[:app_path]

    warn "[Notice] Using Ruby #{RUBY_VERSION}. Please make sure this matches the one used to run your Rails application."

    warn "Processing application in #{options[:app_path]}"
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
  end
end
