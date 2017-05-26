begin
  Brakeman.load_brakeman_dependency 'ruby_parser'
  require 'ruby_parser/bm_sexp.rb'
  require 'ruby_parser/bm_sexp_processor.rb'
  require 'brakeman/processor'
  require 'brakeman/app_tree'
  require 'brakeman/file_parser'
  require 'brakeman/parsers/template_parser'
rescue LoadError => e
  $stderr.puts e.message
  $stderr.puts "Please install the appropriate dependency."
  exit(-1)
end

#Scans the Rails application.
class Brakeman::Scanner
  attr_reader :options
  RUBY_1_9 = RUBY_VERSION >= "1.9.0"

  #Pass in path to the root of the Rails application
  def initialize options, processor = nil
    @options = options
    @app_tree = Brakeman::AppTree.from_options(options)

    if (!@app_tree.root || !@app_tree.exists?("app")) && !options[:force_scan]
      raise Brakeman::NoApplication, "Please supply the path to a Rails application (looking in #{@app_tree.root})."
    end

    @processor = processor || Brakeman::Processor.new(@app_tree, options)
  end

  #Returns the Tracker generated from the scan
  def tracker
    @processor.tracked_events
  end

  #Process everything in the Rails application
  def process
    Brakeman.notify "Processing gems..."
    process_gems
    guess_rails_version
    Brakeman.notify "Processing configuration..."
    process_config
    Brakeman.notify "Parsing files..."
    parse_files
    Brakeman.notify "Processing initializers..."
    process_initializers
    Brakeman.notify "Processing libs..."
    process_libs
    Brakeman.notify "Processing routes...          "
    process_routes
    Brakeman.notify "Processing templates...       "
    process_templates
    Brakeman.notify "Processing data flow in templates..."
    process_template_data_flows
    Brakeman.notify "Processing models...          "
    process_models
    Brakeman.notify "Processing controllers...     "
    process_controllers
    Brakeman.notify "Processing data flow in controllers..."
    process_controller_data_flows
    Brakeman.notify "Indexing call sites...        "
    index_call_sites
    tracker
  end

  def parse_files
    fp = Brakeman::FileParser.new tracker, @app_tree

    files = {
      :initializers => @app_tree.initializer_paths,
      :controllers => @app_tree.controller_paths,
      :models => @app_tree.model_paths
    }

    unless options[:skip_libs]
      files[:libs] = @app_tree.lib_paths
    end

    files.each do |name, paths|
      fp.parse_files paths, name
    end

    template_parser = Brakeman::TemplateParser.new(tracker, fp)

    fp.read_files(@app_tree.template_paths, :templates) do |path, contents|
      template_parser.parse_template path, contents
    end

    @file_list = fp.file_list
  end

  #Process config/environment.rb and config/gems.rb
  #
  #Stores parsed information in tracker.config
  def process_config
    if options[:rails3] or options[:rails4] or options[:rails5]
      process_config_file "application.rb"
      process_config_file "environments/production.rb"
    else
      process_config_file "environment.rb"
      process_config_file "gems.rb"
    end

    if @app_tree.exists?("vendor/plugins/rails_xss") or
      options[:rails3] or options[:escape_html]

      tracker.config.escape_html = true
      Brakeman.notify "[Notice] Escaping HTML by default"
    end

    if @app_tree.exists? ".ruby-version"
      tracker.config.set_ruby_version @app_tree.read ".ruby-version"
    end
  end

  def process_config_file file
    path = "config/#{file}"

    if @app_tree.exists?(path)
      @processor.process_config(parse_ruby(@app_tree.read(path)), path)
    end

  rescue => e
    Brakeman.notify "[Notice] Error while processing #{path}"
    tracker.error e.exception(e.message + "\nwhile processing #{path}"), e.backtrace
  end

  private :process_config_file

  #Process Gemfile
  def process_gems
    gem_files = {}
    if @app_tree.exists? "Gemfile"
      gem_files[:gemfile] = { :src => parse_ruby(@app_tree.read("Gemfile")), :file => "Gemfile" }
    elsif @app_tree.exists? "gems.rb"
      gem_files[:gemfile] = { :src => parse_ruby(@app_tree.read("gems.rb")), :file => "gems.rb" }
    end

    if @app_tree.exists? "Gemfile.lock"
      gem_files[:gemlock] = { :src => @app_tree.read("Gemfile.lock"), :file => "Gemfile.lock" }
    elsif @app_tree.exists? "gems.locked"
      gem_files[:gemlock] = { :src => @app_tree.read("gems.locked"), :file => "gems.locked" }
    end

    if gem_files[:gemfile] or gem_files[:gemlock]
      @processor.process_gems gem_files
    end
  rescue => e
    Brakeman.notify "[Notice] Error while processing Gemfile."
    tracker.error e.exception(e.message + "\nWhile processing Gemfile"), e.backtrace
  end

  #Set :rails3/:rails4 option if version was not determined from Gemfile
  def guess_rails_version
    unless tracker.options[:rails3] or tracker.options[:rails4]
      if @app_tree.exists?("script/rails")
        tracker.options[:rails3] = true
        Brakeman.notify "[Notice] Detected Rails 3 application"
      elsif @app_tree.exists?("app/channels")
        tracker.options[:rails3] = true
        tracker.options[:rails4] = true
        tracker.options[:rails5] = true
        Brakeman.notify "[Notice] Detected Rails 5 application"
      elsif not @app_tree.exists?("script")
        tracker.options[:rails3] = true
        tracker.options[:rails4] = true
        Brakeman.notify "[Notice] Detected Rails 4 application"
      end
    end
  end

  #Process all the .rb files in config/initializers/
  #
  #Adds parsed information to tracker.initializers
  def process_initializers
    track_progress @file_list[:initializers] do |init|
      Brakeman.debug "Processing #{init[:path]}"
      process_initializer init
    end
  end

  #Process an initializer
  def process_initializer init
    @processor.process_initializer(init.path, init.ast)
  end

  #Process all .rb in lib/
  #
  #Adds parsed information to tracker.libs.
  def process_libs
    if options[:skip_libs]
      Brakeman.notify '[Skipping]'
      return
    end

    track_progress @file_list[:libs] do |lib|
      Brakeman.debug "Processing #{lib.path}"
      process_lib lib
    end
  end

  #Process a library
  def process_lib lib
    @processor.process_lib lib.ast, lib.path
  end

  #Process config/routes.rb
  #
  #Adds parsed information to tracker.routes
  def process_routes
    if @app_tree.exists?("config/routes.rb")
      begin
        @processor.process_routes parse_ruby(@app_tree.read("config/routes.rb"))
      rescue => e
        tracker.error e.exception(e.message + "\nWhile processing routes.rb"), e.backtrace
        Brakeman.notify "[Notice] Error while processing routes - assuming all public controller methods are actions."
        options[:assume_all_routes] = true
      end
    else
      Brakeman.notify "[Notice] No route information found"
    end
  end

  #Process all .rb files in controllers/
  #
  #Adds processed controllers to tracker.controllers
  def process_controllers
    track_progress @file_list[:controllers] do |controller|
      Brakeman.debug "Processing #{controller.path}"
      process_controller controller
    end
  end

  def process_controller_data_flows
    controllers = tracker.controllers.sort_by { |name, _| name.to_s }

    track_progress controllers, "controllers" do |name, controller|
      Brakeman.debug "Processing #{name}"
      controller.src.each do |file, src|
        @processor.process_controller_alias name, src, nil, file
      end
    end

    #No longer need these processed filter methods
    tracker.filter_cache.clear
  end

  def process_controller astfile
    begin
      @processor.process_controller(astfile.ast, astfile.path)
    rescue => e
      tracker.error e.exception(e.message + "\nWhile processing #{astfile.path}"), e.backtrace
    end
  end

  #Process all views and partials in views/
  #
  #Adds processed views to tracker.views
  def process_templates
    templates = @file_list[:templates].sort_by { |t| t[:path] }

    track_progress templates, "templates" do |template|
      Brakeman.debug "Processing #{template[:path]}"
      process_template template
    end
  end

  def process_template template
    @processor.process_template(template.name, template.ast, template.type, nil, template.path)
  end

  def process_template_data_flows
    templates = tracker.templates.sort_by { |name, _| name.to_s }

    track_progress templates, "templates" do |name, template|
      Brakeman.debug "Processing #{name}"
      @processor.process_template_alias template
    end
  end

  #Process all the .rb files in models/
  #
  #Adds the processed models to tracker.models
  def process_models
    track_progress @file_list[:models] do |model|
      Brakeman.debug "Processing #{model[:path]}"
      process_model model[:path], model[:ast]
    end
  end

  def process_model path, ast
    @processor.process_model(ast, path)
  end

  def track_progress list, type = "files"
    total = list.length
    current = 0
    list.each do |item|
      report_progress current, total, type
      current += 1
      yield item
    end
  end

  def report_progress(current, total, type = "files")
    return unless @options[:report_progress]
    $stderr.print " #{current}/#{total} #{type} processed\r"
  end

  def index_call_sites
    tracker.index_call_sites
  end

  def parse_ruby input
    RubyParser.new.parse input
  end
end

# This is to allow operation without loading the Haml library
module Haml; class Error < StandardError; end; end
