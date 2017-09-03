require 'set'
require 'brakeman/util'
require 'brakeman/version'
require 'brakeman/report/renderer'
require 'brakeman/processors/output_processor'
require 'brakeman/warning'

# Base class for report formats
class Brakeman::Report::Base
  include Brakeman::Util

  attr_reader :tracker, :checks

  TEXT_CONFIDENCE = Brakeman::Warning::TEXT_CONFIDENCE

  def initialize app_tree, tracker
    @app_tree = app_tree
    @tracker = tracker
    @checks = tracker.checks
    @ignore_filter = tracker.ignored_filter
    @highlight_user_input = tracker.options[:highlight_user_input]
    @warnings_summary = nil
  end

  #Generate table of how many warnings of each warning type were reported
  def generate_warning_overview
    types = warnings_summary.keys
    types.delete :high_confidence
    values = types.sort.collect{|warning_type| [warning_type, warnings_summary[warning_type]] }
    locals = {:types => types, :warnings_summary => warnings_summary}

    render_array('warning_overview', ['Warning Type', 'Total'], values, locals)
  end

  #Generate table of controllers and routes found for those controllers
  def generate_controllers
    controller_rows = []

    tracker.controllers.keys.map{|k| k.to_s}.sort.each do |name|
      name = name.to_sym
      c = tracker.controllers[name]

      if tracker.routes.include? :allow_all_actions or (tracker.routes[name] and tracker.routes[name].include? :allow_all_actions)
        routes = c.methods_public.keys.map{|e| e.to_s}.sort.join(", ")
      elsif tracker.routes[name].nil?
        #No routes defined for this controller.
        #This can happen when it is only a parent class
        #for other controllers, for example.
        routes = "[None]"

      else
        routes = (Set.new(c.methods_public.keys) & tracker.routes[name.to_sym]).
          to_a.
          map {|e| e.to_s}.
          sort.
          join(", ")
      end

      if routes == ""
        routes = "[None]"
      end

      controller_rows << { "Name" => name.to_s,
        "Parent" => c.parent.to_s,
        "Includes" => c.includes.join(", "),
        "Routes" => routes
      }
    end

    cols = ['Name', 'Parent', 'Includes', 'Routes']

    locals = {:controller_rows => controller_rows}
    values = controller_rows.collect{|row| row.values_at(*cols) }
    render_array('controller_overview', cols, values, locals)
  end

  #Generate table of errors or return nil if no errors
  def generate_errors
    values = tracker.errors.collect{|error| [error[:error], error[:backtrace][0]]}
    render_array('error_overview', ['Error', 'Location'], values, {:tracker => tracker})
  end

  def generate_obsolete
    values = tracker.unused_fingerprints.collect{|fingerprint| [fingerprint] }
    render_array('obsolete_ignore_entries', ['fingerprint'], values, {:tracker => tracker})
  end

  def generate_warnings
    render_warnings generic_warnings,
                    :warning,
                    'security_warnings',
                    ["Confidence", "Class", "Method", "Warning Type", "Message"],
                    'Class'
  end

  #Generate table of template warnings or return nil if no warnings
  def generate_template_warnings
    render_warnings template_warnings,
                    :template,
                    'view_warnings',
                    ['Confidence', 'Template', 'Warning Type', 'Message'],
                    'Template'

  end

  #Generate table of model warnings or return nil if no warnings
  def generate_model_warnings
    render_warnings model_warnings,
                    :model,
                    'model_warnings',
                    ['Confidence', 'Model', 'Warning Type', 'Message'],
                    'Model'
  end

  #Generate table of controller warnings or nil if no warnings
  def generate_controller_warnings
    render_warnings controller_warnings,
                    :controller,
                    'controller_warnings',
                    ['Confidence', 'Controller', 'Warning Type', 'Message'],
                    'Controller'
  end

  def generate_ignored_warnings
    render_warnings ignored_warnings,
                    :ignored,
                    'ignored_warnings',
                    ['Confidence', 'Warning Type', 'File', 'Message'],
                    'Warning Type'
  end

  def render_warnings warnings, type, template, cols, sort_col
    unless warnings.empty?
      rows = sort(convert_to_rows(warnings, type), sort_col)

      values = rows.collect { |row| row.values_at(*cols) }

      locals = { :warnings => rows }

      render_array(template, cols, values, locals)
    else
      nil
    end
  end

  def convert_to_rows warnings, type = :warning
    warnings.map do |warning|
      w = warning.to_row type

      case type
      when :warning
        convert_warning w, warning
      when :template
        convert_template_warning w, warning
      when :model
        convert_model_warning w, warning
      when :controller
        convert_controller_warning w, warning
      when :ignored
        convert_ignored_warning w, warning
      end
    end
  end

  def convert_warning warning, original
    warning["Confidence"] = TEXT_CONFIDENCE[warning["Confidence"]]
    warning["Message"] = text_message original, warning["Message"]
    warning
  end

  def convert_template_warning warning, original
    convert_warning warning, original
  end

  def convert_model_warning warning, original
    convert_warning warning, original
  end

  def convert_controller_warning warning, original
    convert_warning warning, original
  end

  def convert_ignored_warning warning, original
    convert_warning warning, original
  end

  def sort rows, sort_col
    stabilizer = 0
    rows.sort_by do |row|
      stabilizer += 1

      row.values_at("Confidence", "Warning Type", sort_col) << stabilizer
    end
  end

  #Return summary of warnings in hash and store in @warnings_summary
  def warnings_summary
    return @warnings_summary if @warnings_summary

    summary = Hash.new(0)
    high_confidence_warnings = 0

    [all_warnings].each do |warnings|
      warnings.each do |warning|
        summary[warning.warning_type.to_s] += 1
        high_confidence_warnings += 1 if warning.confidence == 0
      end
    end

    summary[:high_confidence] = high_confidence_warnings
    @warnings_summary = summary
  end

  def all_warnings
    if @ignore_filter
      @all_warnings ||= @ignore_filter.shown_warnings
    else
      @all_warnings ||= tracker.checks.all_warnings
    end
  end

  def filter_warnings warnings
    if @ignore_filter
      warnings.reject do |w|
        @ignore_filter.ignored? w
      end
    else
      warnings
    end
  end

  def generic_warnings
    filter_warnings tracker.checks.warnings
  end

  def template_warnings
    filter_warnings tracker.checks.template_warnings
  end

  def model_warnings
    filter_warnings tracker.checks.model_warnings
  end

  def controller_warnings
    filter_warnings tracker.checks.controller_warnings
  end

  def ignored_warnings
    if @ignore_filter
      @ignore_filter.ignored_warnings
    else
      []
    end
  end

  def number_of_templates tracker
    Set.new(tracker.templates.map {|k,v| v.name.to_s[/[^.]+/]}).length
  end

  def warning_file warning, absolute = @tracker.options[:absolute_paths]
    return nil if warning.file.nil?

    if absolute
      warning.file
    else
      relative_path warning.file
    end
  end

  def rails_version
    case
    when tracker.config.rails_version
      tracker.config.rails_version
    when tracker.options[:rails4]
      "4.x"
    when tracker.options[:rails3]
      "3.x"
    else
      "Unknown"
    end
  end

  #Escape warning message and highlight user input in text output
  def text_message warning, message
    if @highlight_user_input and warning.user_input
      user_input = warning.format_user_input
      message.gsub(user_input, "+#{user_input}+")
    else
      message
    end
  end
end
