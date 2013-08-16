require 'brakeman/scanner'
require 'terminal-table'
require 'brakeman/util'
require 'brakeman/differ'

#Class for rescanning changed files after an initial scan
class Brakeman::Rescanner < Brakeman::Scanner

  SCAN_ORDER = [:config, :gemfile, :initializer, :lib, :routes, :template,
    :model, :controller]

  #Create new Rescanner to scan changed files
  def initialize options, processor, changed_files
    super(options, processor)

    @paths = changed_files.map {|f| @app_tree.expand_path(f) }
    @old_results = tracker.filtered_warnings  #Old warnings from previous scan
    @changes = nil                 #True if files had to be rescanned
    @reindex = Set.new
  end

  #Runs checks.
  #Will rescan files if they have not already been scanned
  def recheck
    rescan if @changes.nil?

    tracker.run_checks if @changes

    Brakeman::RescanReport.new @old_results, tracker
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
        Brakeman.debug "Rescanning #{path} as #{type}"

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

    unless @app_tree.path_exists?(path)
      return rescan_deleted_file path, type
    end

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
      rescan_lib path
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
      if tracker.config[:gems][:rails_xss] and tracker.config[:escape_html]
        tracker.config[:escape_html] = false
      end

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
        tracker.templates.each do |template_name, template|
          next unless template[:caller]
          unless template[:caller].grep(/^#{name}#/).empty?
            tracker.reset_template template_name
          end
        end

        @processor.process_controller_alias controller[:name], controller[:src]
      end
    end
  end

  def rescan_template path
    return unless path.match KNOWN_TEMPLATE_EXTENSIONS and @app_tree.path_exists?(path)

    template_name = template_path_to_name(path)

    tracker.reset_template template_name
    process_template path

    @processor.process_template_alias tracker.templates[template_name]

    rescan = Set.new

    template_matcher = /^Template:(.+)/
    controller_matcher = /^(.+Controller)#(.+)/
    template_name_matcher = /^#{template_name}\./

    #Search for processed template and process it.
    #Search for rendered versions of template and re-render (if necessary)
    tracker.templates.each do |name, template|
      if template[:file] == path or template[:file].nil?
        next unless template[:caller] and name.to_s.match(template_name_matcher)

        template[:caller].each do |from|
          if from.match(template_matcher)
            rescan << [:template, $1.to_sym]
          elsif from.match(controller_matcher)
            rescan << [:controller, $1.to_sym, $2.to_sym]
          end
        end
      end
    end

    rescan.each do |r|
      if r[0] == :controller
        controller = tracker.controllers[r[1]]

        unless @paths.include? controller[:file]
          @processor.process_controller_alias controller[:name], controller[:src], r[2]
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
    process_model path if @app_tree.path_exists?(path)

    #Only need to rescan other things if a model is added or removed
    if num_models != tracker.models.length
      process_templates
      process_controllers
      @reindex << :templates << :controllers
    end

    @reindex << :models
  end

  def rescan_lib path
    process_lib path if @app_tree.path_exists?(path)

    lib = nil

    tracker.libs.each do |name, library|
      if library[:file] == path
        lib = library
        break
      end
    end

    rescan_mixin lib if lib
  end

  #Handle rescanning when a file is deleted
  def rescan_deleted_file path, type
    case type
    when :controller
      rescan_deleted_controller path
    when :template
      rescan_deleted_template path
    when :model
      rescan_model path
    when :lib
      rescan_deleted_lib path
    when :initializer
      rescan_deleted_initializer path
    else
      if remove_deleted_file path
        return true
      else
        Brakeman.notify "Ignoring deleted file: #{path}"
      end
    end

    true
  end

  def rescan_deleted_controller path
    tracker.reset_controller path
  end

  def rescan_deleted_template path
    return unless path.match KNOWN_TEMPLATE_EXTENSIONS

    template_name = template_path_to_name(path)

    #Remove template
    tracker.reset_template template_name

    rendered_from_controller = /^#{template_name}\.(.+Controller)#(.+)/
    rendered_from_view = /^#{template_name}\.Template:(.+)/

    #Remove any rendered versions, or partials rendered from it
    tracker.templates.delete_if do |name, template|
      if template[:file] == path
        true
      elsif template[:file].nil?
        name = name.to_s

        name.match(rendered_from_controller) or name.match(rendered_from_view)
      end
    end
  end

  def rescan_deleted_lib path
    deleted_lib = nil

    tracker.libs.delete_if do |name, lib|
      if lib[:file] == path
        deleted_lib = lib
        true
      end
    end

    rescan_mixin deleted_lib if deleted_lib
  end

  def rescan_deleted_initializer path
    tracker.initializers.delete Pathname.new(path).basename.to_s
  end

  #Check controllers, templates, models and libs for data from file
  #and delete it.
  def remove_deleted_file path
    deleted = false

    [:controllers, :templates, :models, :libs].each do |collection|
      tracker.send(collection).delete_if do |name, data|
        if data[:file] == path
          deleted = true
          true
        end
      end
    end

    deleted
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
    when /\/config\/.+\.rb/
      :config
    when /Gemfile/
      :gemfile
    else
      :unknown
    end
  end

  def rescan_mixin lib
    method_names = []

    [:public, :private, :protected].each do |access|
      lib[access].each do |name, meth|
        method_names << name
      end
    end

    method_matcher = /##{method_names.map {|n| Regexp.escape(n.to_s)}.join('|')}$/

    #Rescan controllers that mixed in library
    tracker.controllers.each do |name, controller|
      if controller[:includes].include? lib[:name]
        unless @paths.include? controller[:file]
          rescan_file controller[:file]
        end
      end
    end

    to_rescan = []

    #Check if a method from this mixin was used to render a template.
    #This is not precise, because a different controller might have the
    #same method...
    tracker.templates.each do |name, template|
      next unless template[:caller]

      unless template[:caller].grep(method_matcher).empty?
        name.to_s.match /^([^.]+)/

        original = tracker.templates[$1.to_sym]

        if original
          to_rescan << [name, original[:file]]
        end
      end
    end

    to_rescan.each do |template|
      tracker.reset_template template[0]
      rescan_file template[1]
    end
  end
end

#Class to make reporting of rescan results simpler to deal with
class Brakeman::RescanReport
  include Brakeman::Util
  attr_reader :old_results, :new_results

  def initialize old_results, tracker
    @tracker = tracker
    @old_results = old_results
    @all_warnings = nil
    @diff = nil
  end

  #Returns true if any warnings were found (new or old)
  def any_warnings?
    not all_warnings.empty?
  end

  #Returns an array of all warnings found
  def all_warnings
    @all_warnings ||= @tracker.filtered_warnings
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
    @diff ||= Brakeman::Differ.new(all_warnings, @old_results).diff
  end

  #Returns an array of warnings which were in the old report and the new report
  def existing_warnings
    @old ||= all_warnings.select do |w|
      not new_warnings.include? w
    end
  end

  #Output total, fixed, and new warnings
  def to_s(verbose = false)
    if !verbose
      <<-OUTPUT
Total warnings: #{all_warnings.length}
Fixed warnings: #{fixed_warnings.length}
New warnings: #{new_warnings.length}
      OUTPUT
    else
      #Eventually move this to different method, or make default to_s
      out = ""

      {:fixed => fixed_warnings, :new => new_warnings, :existing => existing_warnings}.each do |warning_type, warnings|
        if warnings.length > 0
          out << "#{warning_type.to_s.titleize} warnings: #{warnings.length}\n"

          table = Terminal::Table.new(:headings => ["Confidence", "Class", "Method", "Warning Type", "Message"]) do |t|
            warnings.sort_by { |w| w.confidence}.each do |warning|
              w = warning.to_row

              w["Confidence"] = Brakeman::Report::TEXT_CONFIDENCE[w["Confidence"]]

              t << [w["Confidence"], w["Class"], w["Method"], w["Warning Type"], w["Message"]]
            end
          end
          out << truncate_table(table.to_s)
        end
      end

      out
    end
  end
end
