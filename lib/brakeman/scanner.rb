require 'rubygems'

begin
  require 'ruby_parser'
  require 'ruby_parser/bm_sexp.rb'
  require 'ruby_parser/bm_sexp_processor.rb'
  require 'brakeman/processor'
  require 'brakeman/app_tree'
rescue LoadError => e
  $stderr.puts e.message
  $stderr.puts "Please install the appropriate dependency."
  exit -1
end

#Scans the Rails application.
class Brakeman::Scanner
  attr_reader :options

  RUBY_1_9 = !!(RUBY_VERSION >= "1.9.0")
  KNOWN_TEMPLATE_EXTENSIONS = /.*\.(erb|haml|rhtml|slim)$/

  #Pass in path to the root of the Rails application
  def initialize options, processor = nil
    @options = options
    @app_tree = Brakeman::AppTree.from_options(options)

    if !@app_tree.root || !@app_tree.exists?("app")
      raise Brakeman::NoApplication, "Please supply the path to a Rails application."
    end

    if @app_tree.exists?("script/rails")
      options[:rails3] = true
      Brakeman.notify "[Notice] Detected Rails 3 application"
    elsif not @app_tree.exists?("script")
      options[:rails3] = true # Probably need to do some refactoring
      Brakeman.notify "[Notice] Detected Rails 4 application"
    end

    @ruby_parser = ::RubyParser
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
    Brakeman.notify "Processing configuration..."
    process_config
    Brakeman.notify "Processing initializers..."
    process_initializers
    Brakeman.notify "Processing libs..."
    process_libs
    Brakeman.notify "Processing routes...          "
    process_routes
    Brakeman.notify "Processing templates...       "
    process_templates
    Brakeman.notify "Processing models...          "
    process_models
    Brakeman.notify "Processing controllers...     "
    process_controllers
    Brakeman.notify "Indexing call sites...        "
    index_call_sites
    tracker
  end

  #Process config/environment.rb and config/gems.rb
  #
  #Stores parsed information in tracker.config
  def process_config
    if options[:rails3]
      process_config_file "application.rb"
      process_config_file "environments/production.rb"
    else
      process_config_file "environment.rb"
      process_config_file "gems.rb"
    end

    if @app_tree.exists?("vendor/plugins/rails_xss") or
      options[:rails3] or options[:escape_html]

      tracker.config[:escape_html] = true
      Brakeman.notify "[Notice] Escaping HTML by default"
    end
  end

  def process_config_file file
    path = "config/#{file}"

    if @app_tree.exists?(path)
      @processor.process_config(parse_ruby(@app_tree.read(path)))
    end

  rescue => e
    Brakeman.notify "[Notice] Error while processing #{path}"
    tracker.error e.exception(e.message + "\nwhile processing #{path}"), e.backtrace
  end

  private :process_config_file

  #Process Gemfile
  def process_gems
    if @app_tree.exists? "Gemfile"
      if @app_tree.exists? "Gemfile.lock"
        @processor.process_gems(parse_ruby(@app_tree.read("Gemfile")), @app_tree.read("Gemfile.lock"))
      else
        @processor.process_gems(parse_ruby(@app_tree.read("Gemfile")))
      end
    end
  rescue => e
    Brakeman.notify "[Notice] Error while processing Gemfile."
    tracker.error e.exception(e.message + "\nWhile processing Gemfile"), e.backtrace
  end

  #Process all the .rb files in config/initializers/
  #
  #Adds parsed information to tracker.initializers
  def process_initializers
    @app_tree.initializer_paths.each do |f|
      process_initializer f
    end
  end

  #Process an initializer
  def process_initializer path
    begin
      @processor.process_initializer(path, parse_ruby(@app_tree.read_path(path)))
    rescue Racc::ParseError => e
      tracker.error e, "could not parse #{path}. There is probably a typo in the file. Test it with 'ruby_parse #{path}'"
    rescue => e
      tracker.error e.exception(e.message + "\nWhile processing #{path}"), e.backtrace
    end
  end

  #Process all .rb in lib/
  #
  #Adds parsed information to tracker.libs.
  def process_libs
    if options[:skip_libs]
      Brakeman.notify '[Skipping]'
      return
    end

    total = @app_tree.lib_paths.length
    current = 0

    @app_tree.lib_paths.each do |f|
      Brakeman.debug "Processing #{f}"
      report_progress(current, total)
      current += 1
      process_lib f
    end
  end

  #Process a library
  def process_lib path
    begin
      @processor.process_lib parse_ruby(@app_tree.read_path(path)), path
    rescue Racc::ParseError => e
      tracker.error e, "could not parse #{path}. There is probably a typo in the file. Test it with 'ruby_parse #{path}'"
    rescue => e
      tracker.error e.exception(e.message + "\nWhile processing #{path}"), e.backtrace
    end
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
    total = @app_tree.controller_paths.length
    current = 0

    @app_tree.controller_paths.each do |f|
      Brakeman.debug "Processing #{f}"
      report_progress(current, total)
      current += 1
      process_controller f
    end

    current = 0
    total = tracker.controllers.length

    Brakeman.notify "Processing data flow in controllers..."

    tracker.controllers.sort_by{|name| name.to_s}.each do |name, controller|
      Brakeman.debug "Processing #{name}"
      report_progress(current, total, "controllers")
      current += 1
      @processor.process_controller_alias name, controller[:src]
    end

    #No longer need these processed filter methods
    tracker.filter_cache.clear
  end

  def process_controller path
    begin
      @processor.process_controller(parse_ruby(@app_tree.read_path(path)), path)
    rescue Racc::ParseError => e
      tracker.error e, "could not parse #{path}. There is probably a typo in the file. Test it with 'ruby_parse #{path}'"
    rescue => e
      tracker.error e.exception(e.message + "\nWhile processing #{path}"), e.backtrace
    end
  end

  #Process all views and partials in views/
  #
  #Adds processed views to tracker.views
  def process_templates
    $stdout.sync = true

    count = 0
    total = @app_tree.template_paths.length

    @app_tree.template_paths.each do |path|
      Brakeman.debug "Processing #{path}"
      report_progress(count, total)
      count += 1
      process_template path
    end

    total = tracker.templates.length
    count = 0

    Brakeman.notify "Processing data flow in templates..."

    tracker.templates.keys.dup.sort_by{|name| name.to_s}.each do |name|
      Brakeman.debug "Processing #{name}"
      report_progress(count, total, "templates")
      count += 1
      @processor.process_template_alias tracker.templates[name]
    end
  end

  def process_template path
    type = path.match(KNOWN_TEMPLATE_EXTENSIONS)[1].to_sym
    type = :erb if type == :rhtml
    name = template_path_to_name path
    text = @app_tree.read_path path

    begin
      if type == :erb
        if tracker.config[:escape_html]
          type = :erubis
          if options[:rails3]
            require 'brakeman/parsers/rails3_erubis'
            src = Brakeman::Rails3Erubis.new(text).src
          else
            require 'brakeman/parsers/rails2_xss_plugin_erubis'
            src = Brakeman::Rails2XSSPluginErubis.new(text).src
          end
        elsif tracker.config[:erubis]
          require 'brakeman/parsers/rails2_erubis'
          type = :erubis
          src = Brakeman::ScannerErubis.new(text).src
        else
          require 'erb'
          src = ERB.new(text, nil, "-").src
          src.sub!(/^#.*\n/, '') if RUBY_1_9
        end

        parsed = parse_ruby src
      elsif type == :haml
        Brakeman.load_brakeman_dependency 'haml'
        Brakeman.load_brakeman_dependency 'sass'

        src = Haml::Engine.new(text,
                               :escape_html => !!tracker.config[:escape_html]).precompiled
        parsed = parse_ruby src
      elsif type == :slim
        Brakeman.load_brakeman_dependency 'slim'

        src = Slim::Template.new(:disable_capture => true,
                                 :generator => Temple::Generators::RailsOutputBuffer) { text }.precompiled_template

        parsed = parse_ruby src
      else
        tracker.error "Unkown template type in #{path}"
      end

      @processor.process_template(name, parsed, type, nil, path)

    rescue Racc::ParseError => e
      tracker.error e, "could not parse #{path}"
    rescue Haml::Error => e
      tracker.error e, ["While compiling HAML in #{path}"] << e.backtrace
    rescue StandardError, LoadError => e
      tracker.error e.exception(e.message + "\nWhile processing #{path}"), e.backtrace
    end
  end

  #Convert path/filename to view name
  #
  # views/test/something.html.erb -> test/something
  def template_path_to_name path
    names = path.split("/")
    names.last.gsub!(/(\.(html|js)\..*|\.rhtml)$/, '')
    names[(names.index("views") + 1)..-1].join("/").to_sym
  end

  #Process all the .rb files in models/
  #
  #Adds the processed models to tracker.models
  def process_models
    total = @app_tree.model_paths.length
    current = 0

    @app_tree.model_paths.each do |f|
      Brakeman.debug "Processing #{f}"
      report_progress(current, total)
      current += 1
      process_model f
    end
  end

  def process_model path
    begin
      @processor.process_model(parse_ruby(@app_tree.read_path(path)), path)
    rescue Racc::ParseError => e
      tracker.error e, "could not parse #{path}"
    rescue => e
      tracker.error e.exception(e.message + "\nWhile processing #{path}"), e.backtrace
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
    @ruby_parser.new.parse input
  end
end

# This is to allow operation without loading the Haml library
module Haml; class Error < StandardError; end; end
