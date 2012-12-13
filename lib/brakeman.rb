require 'rubygems'
require 'yaml'
require 'set'

module Brakeman

  #This exit code is used when warnings are found and the --exit-on-warn
  #option is set
  Warnings_Found_Exit_Code = 3

  @debug = false
  @quiet = false

  #Run Brakeman scan. Returns Tracker object.
  #
  #Options:
  #
  #  * :app_path - path to root of Rails app (required)
  #  * :assume_all_routes - assume all methods are routes (default: false)
  #  * :check_arguments - check arguments of methods (default: true)
  #  * :collapse_mass_assignment - report unprotected models in single warning (default: true)
  #  * :combine_locations - combine warning locations (default: true)
  #  * :config_file - configuration file
  #  * :escape_html - escape HTML by default (automatic)
  #  * :exit_on_warn - return false if warnings found, true otherwise. Not recommended for library use (default: false)
  #  * :highlight_user_input - highlight user input in reported warnings (default: true)
  #  * :html_style - path to CSS file
  #  * :ignore_model_output - consider models safe (default: false)
  #  * :interprocedural - limited interprocedural processing of method calls (default: false)
  #  * :message_limit - limit length of messages
  #  * :min_confidence - minimum confidence (0-2, 0 is highest)
  #  * :output_files - files for output
  #  * :output_formats - formats for output (:to_s, :to_tabs, :to_csv, :to_html)
  #  * :parallel_checks - run checks in parallel (default: true)
  #  * :print_report - if no output file specified, print to stdout (default: false)
  #  * :quiet - suppress most messages (default: true)
  #  * :rails3 - force Rails 3 mode (automatic)
  #  * :report_routes - show found routes on controllers (default: false)
  #  * :run_checks - array of checks to run (run all if not specified)
  #  * :safe_methods - array of methods to consider safe
  #  * :skip_libs - do not process lib/ directory (default: false)
  #  * :skip_checks - checks not to run (run all if not specified)
  #  * :relative_path - show relative path of each file(default: false)
  #  * :summary_only - only output summary section of report
  #                    (does not apply to tabs format)
  #
  #Alternatively, just supply a path as a string.
  def self.run options
    options = set_options options

    @quiet = !!options[:quiet]
    @debug = !!options[:debug]

    if @quiet
      options[:report_progress] = false
    end
    scan options
  end

  #Sets up options for run, checks given application path
  def self.set_options options
    if options.is_a? String
      options = { :app_path => options }
    end

    options[:app_path] = File.expand_path(options[:app_path])

    options = load_options(options[:config_file]).merge! options
    options = get_defaults.merge! options
    options[:output_formats] = get_output_formats options

    options
  end

  DEPRECATED_CONFIG_FILES = [
    File.expand_path("./config.yaml"),
    File.expand_path("~/.brakeman/config.yaml"),
    File.expand_path("/etc/brakeman/config.yaml"),
    "#{File.expand_path(File.dirname(__FILE__))}/../lib/config.yaml"
  ]

  CONFIG_FILES = [
    File.expand_path("./config/brakeman.yml"),
    File.expand_path("~/.brakeman/config.yml"),
    File.expand_path("/etc/brakeman/config.yml"),
  ]

  #Load options from YAML file
  def self.load_options custom_location
    #Load configuration file
    if config = config_file(custom_location)
      notify "[Notice] Using configuration in #{config}"
      options = YAML.load_file config
      options.each { |k, v| options[k] = Set.new v if v.is_a? Array }
      options
    else
      {}
    end
  end

  def self.config_file(custom_location=nil)
    DEPRECATED_CONFIG_FILES.each do |f|
      notify "#{f} is deprecated, please use one of #{CONFIG_FILES.join(", ")}" if File.file?(f)
    end
    supported_locations = [File.expand_path(custom_location || "")] + DEPRECATED_CONFIG_FILES + CONFIG_FILES
    supported_locations.detect{|f| File.file?(f) }
  end

  #Default set of options
  def self.get_defaults
    { :skip_checks => Set.new,
      :check_arguments => true,
      :safe_methods => Set.new,
      :min_confidence => 2,
      :combine_locations => true,
      :collapse_mass_assignment => true,
      :highlight_user_input => true,
      :ignore_redirect_to_model => true,
      :ignore_model_output => false,
      :message_limit => 100,
      :parallel_checks => true,
      :relative_path => false,
      :quiet => true,
      :report_progress => true,
      :html_style => "#{File.expand_path(File.dirname(__FILE__))}/brakeman/format/style.css"
    }
  end

  #Determine output formats based on options[:output_formats]
  #or options[:output_files]
  def self.get_output_formats options
    #Set output format
    if options[:output_format] && options[:output_files] && options[:output_files].size > 1
      raise ArgumentError, "Cannot specify output format if multiple output files specified"
    end
    if options[:output_format]
      [
        case options[:output_format]
        when :html, :to_html
          :to_html
        when :csv, :to_csv
          :to_csv
        when :pdf, :to_pdf
          :to_pdf
        when :tabs, :to_tabs
          :to_tabs
        when :json, :to_json
          :to_json
        else
          :to_s
        end
      ]
    else
      return [:to_s] unless options[:output_files]
      options[:output_files].map do |output_file|
        case output_file
        when /\.html$/i
          :to_html
        when /\.csv$/i
          :to_csv
        when /\.pdf$/i
          :to_pdf
        when /\.tabs$/i
          :to_tabs
        when /\.json$/i
          :to_json
        else
          :to_s
        end
      end
    end
  end

  #Output list of checks (for `-k` option)
  def self.list_checks
    require 'brakeman/scanner'
    $stderr.puts "Available Checks:"
    $stderr.puts "-" * 30
    $stderr.puts Checks.checks.map { |c|
      c.to_s.match(/^Brakeman::(.*)$/)[1].ljust(27) << c.description
    }.sort.join "\n"
  end

  #Installs Rake task for running Brakeman,
  #which basically means copying `lib/brakeman/brakeman.rake` to
  #`lib/tasks/brakeman.rake` in the current Rails application.
  def self.install_rake_task
    if not File.exists? "Rakefile"
      abort "No Rakefile detected"
    elsif File.exists? "lib/tasks/brakeman.rake"
      abort "Task already exists"
    end

    require 'fileutils'

    if not File.exists? "lib/tasks"
      notify "Creating lib/tasks"
      FileUtils.mkdir_p "lib/tasks"
    end

    path = File.expand_path(File.dirname(__FILE__))

    FileUtils.cp "#{path}/brakeman/brakeman.rake", "lib/tasks/brakeman.rake"

    if File.exists? "lib/tasks/brakeman.rake"
      notify "Task created in lib/tasks/brakeman.rake"
      notify "Usage: rake brakeman:run[output_file]"
    else
      notify "Could not create task"
    end
  end

  #Output configuration to YAML
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

  #Run a scan. Generally called from Brakeman.run instead of directly.
  def self.scan options
    #Load scanner
    notify "Loading scanner..."

    begin
      require 'brakeman/scanner'
    rescue LoadError
      abort "Cannot find lib/ directory."
    end

    #Start scanning
    scanner = Scanner.new options

    notify "Processing application in #{options[:app_path]}"
    tracker = scanner.process

    if options[:parallel_checks]
      notify "Running checks in parallel..."
    else
      notify "Runnning checks..."
    end
    tracker.run_checks

    if options[:output_files]
      notify "Generating report..."

      options[:output_files].each_with_index do |output_file, idx|
        File.open output_file, "w" do |f|
          f.write tracker.report.send(options[:output_formats][idx])
        end
        notify "Report saved in '#{output_file}'"
      end
    elsif options[:print_report]
      notify "Generating report..."

      options[:output_formats].each do |output_format|
        puts tracker.report.send(output_format)
      end
    end

    tracker
  end

  #Rescan a subset of files in a Rails application.
  #
  #A full scan must have been run already to use this method.
  #The returned Tracker object from Brakeman.run is used as a starting point
  #for the rescan.
  #
  #Options may be given as a hash with the same values as Brakeman.run.
  #Note that these options will be merged into the Tracker.
  #
  #This method returns a RescanReport object with information about the scan.
  #However, the Tracker object will also be modified as the scan is run.
  def self.rescan tracker, files, options = {}
    require 'brakeman/rescanner'

    tracker.options.merge! options

    @quiet = !!tracker.options[:quiet]
    @debug = !!tracker.options[:debug]

    Rescanner.new(tracker.options, tracker.processor, files).recheck
  end

  def self.notify message
    $stderr.puts message unless @quiet
  end

  def self.debug message
    $stderr.puts message if @debug
  end

  # Compare JSON ouptut from a previous scan and return the diff of the two scans
  def self.compare options
    require 'multi_json'
    require 'brakeman/differ'
    raise ArgumentError.new("Comparison file doesn't exist") unless File.exists? options[:previous_results_json]

    begin
      previous_results = MultiJson.load(File.read(options[:previous_results_json]), :symbolize_keys => true)[:warnings]
    rescue MultiJson::DecodeError
      self.notify "Error parsing comparison file: #{options[:previous_results_json]}"
      exit!
    end

    tracker = run(options)

    new_results = MultiJson.load(tracker.report.to_json, :symbolize_keys => true)[:warnings]

    Brakeman::Differ.new(new_results, previous_results).diff
  end
end
