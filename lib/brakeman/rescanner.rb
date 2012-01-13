require 'brakeman/scanner'

#Class for rescanning changed files after an initial scan
class Brakeman::Rescanner < Brakeman::Scanner

  SCAN_ORDER = [:config, :gemfile, :initializer, :lib, :routes, :template,
    :model, :controller]

  #Create new Rescanner to scan changed files
  def initialize options, processor, changed_files
    super(options, processor)

    @paths = changed_files.map {|f| File.expand_path f, tracker.options[:app_path] }
    @old_results = tracker.checks  #Old warnings from previous scan
    @changes = nil                 #True if files had to be rescanned
    @reindex = Set.new
  end

  #Runs checks.
  #Will rescan files if they have not already been scanned
  def recheck
    rescan if @changes.nil?

    tracker.run_checks if @changes

    Brakeman::RescanReport.new @old_results, tracker.checks
  end

  #Rescans changed files
  def rescan
    tracker.template_cache.clear

    paths_by_type = {}

    SCAN_ORDER.each do |type|
      paths_by_type[type] = []
    end

    @paths.each do |path|
      type = file_type(path)
      paths_by_type[type] << path unless type == :unknown
    end

    @changes = false

    SCAN_ORDER.each do |type|
      paths_by_type[type].each do |path|
        warn "Rescanning #{path} as #{type}" if tracker.options[:debug]

        if rescan_file path, type
          @changes = true
        end
      end
    end

    if @changes and not @reindex.empty?
      tracker.reindex_call_sites @reindex
    end

    self
  end

  #Rescans a single file
  def rescan_file path, type = nil
    type ||= file_type path

    case type
    when :controller
      rescan_controller path
      @reindex << :controllers << :templates
    when :template
      rescan_template path
      @reindex << :templates
    when :model
      rescan_model path
    when :lib
      process_library path
    when :config
      process_config
    when :initializer
      process_initializer path
    when :routes
      # Routes affect which controller methods are treated as actions
      # which affects which templates are rendered, so routes, controllers,
      # and templates rendered from controllers must be rescanned
      tracker.reset_routes
      tracker.reset_templates :only_rendered => true
      process_routes
      process_controllers
      @reindex << :controllers << :templates
    when :gemfile
      process_gems
    else
      return false #Nothing to do, file hopefully does not need to be rescanned
    end

    true
  end

  def rescan_controller path
    #Process source
    process_controller path

    #Process data flow and template rendering
    #from the controller
    tracker.controllers.each do |name, controller|
      if controller[:file] == path
        tracker.templates.keys.each do |template_name|
          if template_name.to_s.match /(.+)\.#{name}#/
            tracker.templates.delete template_name
          end
        end

        @processor.process_controller_alias controller[:src]
      end
    end
  end

  def rescan_template path
    template_name = template_path_to_name(path)

    tracker.reset_template template_name
    process_template path

    @processor.process_template_alias tracker.templates[template_name]

    rescan = Set.new

    rendered_from_controller = /^#{template_name}\.(.+Controller)#(.+)/
    rendered_from_view = /^#{template_name}\.Template:(.+)/

    #Search for processed template and process it.
    #Search for rendered versions of template and re-render (if necessary)
    tracker.templates.each do |name, template|
      if template[:file] == path or template[:file].nil?
       name = name.to_s

       if name.match(rendered_from_controller)
         #Rendered from controller, so reprocess controller

         rescan << [:controller, $1.to_sym, $2.to_sym]
       elsif name.match(rendered_from_view)
         #Rendered from another template, so reprocess that template

         rescan << [:template, $1.to_sym]
       end
      end
    end

    rescan.each do |r|
      if r[0] == :controller
        controller = tracker.controllers[r[1]]

        unless @paths.include? controller[:file]
          @processor.process_controller_alias controller[:src], r[2]
        end
      elsif r[0] == :template
        template = tracker.templates[r[1]]

        rescan_template template[:file]
      end
    end
  end

  def rescan_model path
    num_models = tracker.models.length
    tracker.reset_model path
    process_model path if File.exists? path

    #Only need to rescan other things if a model is added or removed
    if num_models != tracker.models.length
      process_templates
      process_controllers
      @reindex << :templates << :controllers
    end

    @reindex << :models
  end

  #Guess at what kind of file the path contains
  def file_type path
    case path
    when /\/app\/controllers/
      :controller
    when /\/app\/views/
      :template
    when /\/app\/models/
      :model
    when /\/lib/
      :lib
    when /\/config\/initializers/
      :initializer
    when /config\/routes\.rb/
      :routes
    when /\/config/
      :config
    when /Gemfile/
      :gemfile
    else
      :unknown
    end
  end
end

#Class to make reporting of rescan results simpler to deal with
class Brakeman::RescanReport
  attr_reader :old_results, :new_results

  def initialize old_results, new_results
    @old_results = old_results
    @new_results = new_results
    @all_warnings = nil
    @diff = nil
  end

  #Returns true if any warnings were found (new or old)
  def any_warnings?
    not all_warnings.empty?
  end

  #Returns an array of all warnings found
  def all_warnings
    @all_warnings ||= new_results.all_warnings
  end

  #Returns an array of warnings which were in the old report but are not in the
  #new report after rescanning
  def fixed_warnings
    diff[:fixed]
  end

  #Returns an array of warnings which were in the new report but were not in
  #the old report
  def new_warnings
    diff[:new]
  end

  #Returns true if there are any new or fixed warnings
  def warnings_changed?
    not (diff[:new].empty? and diff[:fixed].empty?)
  end

  #Returns a hash of arrays for :new and :fixed warnings
  def diff
    @diff ||= @new_results.diff(@old_results)
  end
end
