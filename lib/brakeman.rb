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
  #  * :check_updates - check for newer version of Brakeman (default: false)
  #  * :collapse_mass_assignment - report unprotected models in single warning (default: true)
  #  * :combine_locations - combine warning locations (default: true)
  #  * :config_file - configuration file
  #  * :escape_html - escape HTML by default (automatic)
  #  * :exit_on_warn - return false if warnings found, true otherwise. Not recommended for library use (default: false)
  #  * :html_style - path to CSS file
  #  * :ignore_model_output - consider models safe (default: false)
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

    if options[:check_updates]
      self.warn_on_outdated
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

    app_path = options[:app_path]

    abort("Please supply the path to a Rails application.") unless app_path and File.exist? app_path + "/app"

    if File.exist? app_path + "/script/rails"
      options[:rails3] = true
      notify "[Notice] Detected Rails 3 application"
    end

    options
  end

  #Load options from YAML file
  def self.load_options config_file
    config_file ||= ""

    #Load configuration file
    [File.expand_path(config_file),
      File.expand_path("./config.yaml"),
      File.expand_path("~/.brakeman/config.yaml"),
      File.expand_path("/etc/brakeman/config.yaml"),
      "#{File.expand_path(File.dirname(__FILE__))}/../lib/config.yaml"].each do |f|

      if File.exist? f and not File.directory? f
        notify "[Notice] Using configuration in #{f}"
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

  #Default set of options
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
      :parallel_checks => true,
      :quiet => true,
      :report_progress => true,
      :html_style => "#{File.expand_path(File.dirname(__FILE__))}/brakeman/format/style.css",
      :check_updates => false
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

    notify "[Notice] Using Ruby #{RUBY_VERSION}. Please make sure this matches the one used to run your Rails application."

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

  #Check for a newer version of Brakeman. If found, suggest updating.
  #
  #Results of this check are stored in ~/.brakeman/update_check, and should
  #only update once per 24 hours.
  #
  #This check is ON by default when running Brakeman from the command line,
  #but OFF by default when using Brakeman as a library.
  #
  #~/.brakeman/update_check contains a version number on the first line and
  #a timestamp on the second line.
  def self.warn_on_outdated
    require 'date'

    brakeman_path = File.expand_path "~/.brakeman"
    last_check_file = File.join(brakeman_path, "update_check")
    current_time = DateTime.now
    last_time = 0

    if File.exist? last_check_file
      latest, last_time = File.readlines(last_check_file)
      latest.strip!
      last_time.strip!

      begin
        last_time = DateTime.parse last_time
      rescue ArgumentError
        last_time = nil
      end
    elsif not File.exist? brakeman_path
      #If we can't create a file to keep track of when the version was last
      #checked, then don't warn at all
      begin
        Dir.mkdir brakeman_path
      rescue Errno::EACCES
        return
      end
    end

    if latest.nil? or last_time - current_time > 86400
      latest = self.latest_version

      File.open last_check_file, "w" do |f|
        f.puts latest
        f.puts current_time
      end
    end

    if latest > Brakeman::Version
      Brakeman.notify "[Notice] Please upgrade to latest version: #{latest}"
    end

  rescue Exception => e
    notify "[Notice] Error while checking latest version information: #{e}"
    puts e.backtrace
  end

  #Returns latest version of Brakeman
  def self.latest_version
    Brakeman.notify "Checking for latest Brakeman version..."
    current_version = Brakeman::Version
    brakeman_dependency = Gem::Dependency.new("brakeman", ">#{current_version}")
    specs = Gem::SpecFetcher.new.find_matching(brakeman_dependency)

    if specs.empty?
      current_version
    else
      specs[0][0][1].version
    end
  rescue Exception => e
    notify "[Notice] Error while fetching latest version information: #{e}"
    current_version
  end

  def self.notify message
    $stderr.puts message unless @quiet
  end

  def self.debug message
    $stderr.puts message if @debug
  end
end
