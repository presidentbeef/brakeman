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

  def controller_information
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

    controller_rows
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
end
