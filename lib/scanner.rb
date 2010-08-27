require 'rubygems'
begin
  require 'ruby_parser'
  require 'haml'
  require 'erb'
  require 'erubis'
  require 'processor'
rescue LoadError => e
  $stderr.puts e.message
  $stderr.puts "Please install the appropriate dependency."
  exit
end

#Erubis processor which ignores any output which is plain text.
class ScannerErubis < Erubis::Eruby
  include Erubis::NoTextEnhancer
end

#Scans the Rails application.
class Scanner

  #Pass in path to the root of the Rails application
  def initialize path
    @path = path
    @app_path = path + "/app/"
    @processor = Processor.new
  end

  #Returns the Tracker generated from the scan
  def tracker
    @processor.tracked_events
  end

  #Process everything in the Rails application
  def process
    warn "Processing configuration..."
    process_config
    warn "Processing initializers..."
    process_initializers
    warn "Processing libs..."
    process_libs
    warn "Processing routes..."
    process_routes
    warn "Processing templates..."
    process_templates
    warn "Processing models..."
    process_models
    warn "Processing controllers..."
    process_controllers
    tracker
  end

  #Process config/environment.rb and config/gems.rb
  #
  #Stores parsed information in tracker.config
  def process_config
    @processor.process_config(RubyParser.new.parse(File.read("#@path/config/environment.rb")))

    if File.exists? "#@path/config/gems.rb"
      @processor.process_config(RubyParser.new.parse(File.read("#@path/config/gems.rb")))
    end

    if File.exists? "#@path/vendor/plugins/rails_xss"
      tracker.config[:escape_html] = true
      warn "[Notice] Escaping HTML by default"
    end
  end

  #Process all the .rb files in config/initializers/
  #
  #Adds parsed information to tracker.initializers
  def process_initializers
    Dir.glob(@path + "/config/initializers/**/*.rb").sort.each do |f|
      begin
        @processor.process_initializer(f, RubyParser.new.parse(File.read(f)))
      rescue Racc::ParseError => e
        tracker.error e, "could not parse #{f}"
      rescue Exception => e
        tracker.error e.exception(e.message + "\nWhile processing #{f}"), e.backtrace
      end
    end
  end

  #Process all .rb in lib/
  #
  #Adds parsed information to tracker.libs.
  def process_libs
    Dir.glob(@path + "/lib/**/*.rb").sort.each do |f|
      begin
        @processor.process_lib RubyParser.new.parse(File.read(f)), f
      rescue Racc::ParseError => e
        tracker.error e, "could not parse #{f}"
      rescue Exception => e
        tracker.error e.exception(e.message + "\nWhile processing #{f}"), e.backtrace
      end
    end
  end

  #Process config/routes.rb
  #
  #Adds parsed information to tracker.routes
  def process_routes
    if File.exists? "#@path/config/routes.rb"
      @processor.process_routes RubyParser.new.parse(File.read("#@path/config/routes.rb"))
    end
  end

  #Process all .rb files in controllers/
  #
  #Adds processed controllers to tracker.controllers
  def process_controllers
    Dir.glob(@app_path + "/controllers/**/*.rb").sort.each do |f|
      begin
        @processor.process_controller(RubyParser.new.parse(File.read(f)), f)
      rescue Racc::ParseError => e
        tracker.error e, "could not parse #{f}"
      rescue Exception => e
        tracker.error e.exception(e.message + "\nWhile processing #{f}"), e.backtrace
      end
    end

    tracker.controllers.each do |name, controller|
      @processor.process_controller_alias controller[:src]
    end
  end

  #Process all views and partials in views/
  #
  #Adds processed views to tracker.views
  def process_templates

    views_path = @app_path + "/views/**/*.{html.erb,html.haml,rhtml,js.erb}"
    $stdout.sync = true
    count = 0

    Dir.glob(views_path).sort.each do |f|
      count += 1
      type = f.match(/.*\.(erb|haml|rhtml)$/)[1].to_sym
      type = :erb if type == :rhtml
      name = template_path_to_name f

      begin
        if type == :erb
          if tracker.config[:escape_html]
            src = RailsXSSErubis.new(File.read(f)).src
          elsif tracker.config[:erubis]
            src = ScannerErubis.new(File.read(f)).src
          else
            src = ERB.new(File.read(f), nil, "-").src
          end
          parsed = RubyParser.new.parse src
        elsif type == :haml
          src = Haml::Engine.new(File.read(f),
                                 :escape_html => !!tracker.config[:escape_html]).precompiled
          parsed = RubyParser.new.parse src
        else
          tracker.error "Unkown template type in #{f}"
        end

        @processor.process_template(name, parsed, type, nil, f)

      rescue Racc::ParseError => e
        tracker.error e, "could not parse #{f}"
      rescue Haml::Error => e
        tracker.error e, ["While compiling HAML in #{f}"] << e.backtrace
      rescue Exception => e
        tracker.error e.exception(e.message + "\nWhile processing #{f}"), e.backtrace
      end
    end

    tracker.templates.keys.dup.each do |name|
      @processor.process_template_alias tracker.templates[name]
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
    Dir.glob(@app_path + "/models/*.rb").sort.each do |f|
      begin
        @processor.process_model(RubyParser.new.parse(File.read(f)), f)
      rescue Racc::ParseError => e
        tracker.error e, "could not parse #{f}"
      rescue Exception => e
        tracker.error e.exception(e.message + "\nWhile processing #{f}"), e.backtrace
      end
    end
  end
end

#This is from the rails_xss plugin,
#except we don't care about plain text.
class RailsXSSErubis < ::Erubis::Eruby
  include Erubis::NoTextEnhancer

  #Initializes output buffer.
  def add_preamble(src)
    src << "@output_buffer = ActionView::SafeBuffer.new;\n"
  end

  #This does nothing.
  def add_text(src, text)
    #    src << "@output_buffer << ('" << escape_text(text) << "'.html_safe!);"
  end

  #Add an expression to the output buffer _without_ escaping.
  def add_expr_literal(src, code)
    src << '@output_buffer << ((' << code << ').to_s);'
  end

  #Add an expression to the output buffer after escaping it.
  def add_expr_escaped(src, code)
    src << '@output_buffer << ' << escaped_expr(code) << ';'
  end

  #Add code to output buffer.
  def add_postamble(src)
    src << '@output_buffer.to_s'
  end
end

