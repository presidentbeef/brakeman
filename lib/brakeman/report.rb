require 'cgi'
require 'set'
require 'brakeman/processors/output_processor'
require 'brakeman/util'
require 'terminal-table'
require 'highline/system_extensions'
require "csv"
require 'multi_json'
require 'brakeman/version'
require 'brakeman/report/renderer'
require 'brakeman/report/overview'
Dir[File.dirname(__FILE__) + 'report/initializers/*.rb'].each {|file| require file}

#Generates a report based on the Tracker and the results of
#Tracker#run_checks. Be sure to +run_checks+ before generating
#a report.
class Brakeman::Report
  include Brakeman::Util

  attr_reader :tracker, :checks

  TEXT_CONFIDENCE = [ "High", "Medium", "Weak" ]
  HTML_CONFIDENCE = [ "<span class='high-confidence'>High</span>",
                     "<span class='med-confidence'>Medium</span>",
                     "<span class='weak-confidence'>Weak</span>" ]

  def initialize(app_tree, tracker)
    @app_tree = app_tree
    @tracker = tracker
    @checks = tracker.checks
    @warnings_summary = nil
    @highlight_user_input = tracker.options[:highlight_user_input]
  end

  #Generate summary table of what was parsed
  def generate_overview html = false
    Brakeman::Report::Overview::General.new(@app_tree, @tracker, all_warnings).report(html)
  end

  #Generate table of how many warnings of each warning type were reported
  def generate_warning_overview html = false
    Brakeman::Report::Overview::Warning.new(@app_tree, @tracker, all_warnings).report(html)
  end

  #Generate table of errors or return nil if no errors
  def generate_errors html = false
    Brakeman::Report::Overview::Error.new(@app_tree, @tracker, all_warnings).report(html)
  end

  # TODO: REMOVE
  def render_array(template, headings, value_array, locals, html = false)
    return if value_array.empty?
    if html
      Brakeman::Report::Renderer.new(template, :locals => locals).render
    else
      Terminal::Table.new(:headings => headings) do |t|
        value_array.each { |value_row| t.add_row value_row }
      end
    end
  end

  #Generate table of general security warnings
  def generate_warnings html = false
    Brakeman::Report::Overview::Security.new(@app_tree, @tracker, all_warnings).report(html)
  end

  #Generate table of template warnings or return nil if no warnings
  def generate_template_warnings html = false
    Brakeman::Report::Overview::TemplateWarning.new(@app_tree, @tracker, all_warnings).report(html)
  end

  #Generate table of model warnings or return nil if no warnings
  def generate_model_warnings html = false
    Brakeman::Report::Overview::Model.new(@app_tree, @tracker, all_warnings).report(html)
  end

  #Generate table of controller warnings or nil if no warnings
  def generate_controller_warnings html = false
    Brakeman::Report::Overview::ControllerWarning.new(@app_tree, @tracker, all_warnings).report(html)
  end

  #Generate table of controllers and routes found for those controllers
  def generate_controllers html=false
    Brakeman::Report::Overview::Controller.new(@app_tree, @tracker, all_warnings).report(html)
  end

  #Generate listings of templates and their output
  def generate_templates html = false
    Brakeman::Report::Overview::Template.new(@app_tree, @tracker, all_warnings).report(html)
  end

  #Generate HTML output
  def to_html
    out = html_header
    out << generate_overview(true)
    out << generate_warning_overview(true).to_s

    # Return early if only summarizing
    return out if tracker.options[:summary_only]

    out << generate_controllers(true).to_s if tracker.options[:report_routes] or tracker.options[:debug]
    out << generate_templates(true).to_s if tracker.options[:debug]
    out << generate_errors(true).to_s
    out << generate_warnings(true).to_s
    out << generate_controller_warnings(true).to_s
    out << generate_model_warnings(true).to_s
    out << generate_template_warnings(true).to_s
    out << "</body></html>"
  end

  #Output text version of the report
  def to_s
    out = text_header <<
    "\n\n+SUMMARY+\n\n" <<
    truncate_table(generate_overview.to_s) << "\n\n" <<
    truncate_table(generate_warning_overview.to_s) << "\n"

    #Return output early if only summarizing
    return out if tracker.options[:summary_only]

    if tracker.options[:report_routes] or tracker.options[:debug]
      out << "\n+CONTROLLERS+\n" <<
      truncate_table(generate_controllers.to_s) << "\n"
    end

    if tracker.options[:debug]
      out << "\n+TEMPLATES+\n\n" <<
      truncate_table(generate_templates.to_s) << "\n"
    end

    res = generate_errors
    out << "+Errors+\n" << truncate_table(res.to_s) if res

    res = generate_warnings
    out << "\n\n+SECURITY WARNINGS+\n\n" << truncate_table(res.to_s) if res

    res = generate_controller_warnings
    out << "\n\n\nController Warnings:\n\n" << truncate_table(res.to_s) if res

    res = generate_model_warnings
    out << "\n\n\nModel Warnings:\n\n" << truncate_table(res.to_s) if res

    res = generate_template_warnings
    out << "\n\nView Warnings:\n\n" << truncate_table(res.to_s) if res

    out << "\n"
    out
  end

  #Generate CSV output
  def to_csv
    output = csv_header
    output << "\nSUMMARY\n"

    output << table_to_csv(generate_overview) << "\n"

    output << table_to_csv(generate_warning_overview) << "\n"

    #Return output early if only summarizing
    if tracker.options[:summary_only]
      return output
    end

    if tracker.options[:report_routes] or tracker.options[:debug]
      output << "CONTROLLERS\n"
      output << table_to_csv(generate_controllers) << "\n"
    end

    if tracker.options[:debug]
      output << "TEMPLATES\n\n"
      output << table_to_csv(generate_templates) << "\n"
    end

    res = generate_errors
    output << "ERRORS\n" << table_to_csv(res) << "\n" if res

    res = generate_warnings
    output << "SECURITY WARNINGS\n" << table_to_csv(res) << "\n" if res

    output << "Controller Warnings\n"
    res = generate_controller_warnings
    output << table_to_csv(res) << "\n" if res

    output << "Model Warnings\n"
    res = generate_model_warnings
    output << table_to_csv(res) << "\n" if res

    res = generate_template_warnings
    output << "Template Warnings\n"
    output << table_to_csv(res) << "\n" if res

    output
  end

  #Not yet implemented
  def to_pdf
    raise "PDF output is not yet supported."
  end

  def rails_version
    return tracker.config[:rails_version] if tracker.config[:rails_version]
    return "3.x" if tracker.options[:rails3]
    "Unknown"
  end

  #Return header for HTML output. Uses CSS from tracker.options[:html_style]
  def html_header
    if File.exist? tracker.options[:html_style]
      css = File.read tracker.options[:html_style]
    else
      raise "Cannot find CSS stylesheet for HTML: #{tracker.options[:html_style]}"
    end

    locals = {
      :css => css,
      :tracker => tracker,
      :checks => checks,
      :rails_version => rails_version,
      :brakeman_version => Brakeman::Version
      }

    Brakeman::Report::Renderer.new('header', :locals => locals).render
  end

  #Generate header for text output
  def text_header
    <<-HEADER

+BRAKEMAN REPORT+

Application path: #{File.expand_path tracker.options[:app_path]}
Rails version: #{rails_version}
Brakeman version: #{Brakeman::Version}
Started at #{tracker.start_time}
Duration: #{tracker.duration} seconds
Checks run: #{checks.checks_run.sort.join(", ")}
HEADER
  end

  #Generate header for CSV output
  def csv_header
    header = CSV.generate_line(["Application Path", "Report Generation Time", "Checks Performed", "Rails Version"])
    header << CSV.generate_line([File.expand_path(tracker.options[:app_path]), Time.now.to_s, checks.checks_run.sort.join(", "), rails_version])
    "BRAKEMAN REPORT\n\n" + header
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


  #Generated tab-separated output suitable for the Jenkins Brakeman Plugin:
  #https://github.com/presidentbeef/brakeman-jenkins-plugin
  def to_tabs
    [[:warnings, "General"], [:controller_warnings, "Controller"],
      [:model_warnings, "Model"], [:template_warnings, "Template"]].map do |meth, category|

      checks.send(meth).map do |w|
        line = w.line || 0
        w.warning_type.gsub!(/[^\w\s]/, ' ')
        "#{warning_file w}\t#{line}\t#{w.warning_type}\t#{category}\t#{w.format_message}\t#{TEXT_CONFIDENCE[w.confidence]}"
      end.join "\n"

    end.join "\n"
  end

  def to_test
    report = { :errors => tracker.errors,
               :controllers => tracker.controllers,
               :models => tracker.models,
               :templates => tracker.templates
              }

    [:warnings, :controller_warnings, :model_warnings, :template_warnings].each do |meth|
      report[meth] = @checks.send(meth)
      report[meth].each do |w|
        w.message = w.format_message
        if w.code
          w.code = w.format_code
        else
          w.code = ""
        end
        w.context = context_for(@app_tree, w).join("\n")
      end
    end

    report[:config] = tracker.config

    report
  end

  def to_json
    errors = tracker.errors.map{|e| { :error => e[:error], :location => e[:backtrace][0] }}
    app_path = tracker.options[:app_path]

    warnings = all_warnings.map do |w|
      hash = w.to_hash
      hash[:file] = warning_file w
      hash
    end.sort_by { |w| w[:file] }

    scan_info = {
      :app_path => File.expand_path(tracker.options[:app_path]),
      :rails_version => rails_version,
      :security_warnings => all_warnings.length,
      :start_time => tracker.start_time.to_s,
      :end_time => tracker.end_time.to_s,
      :timestamp => tracker.end_time.to_s,
      :duration => tracker.duration,
      :checks_performed => checks.checks_run.sort,
      :number_of_controllers =>tracker.controllers.length,
      # ignore the "fake" model
      :number_of_models => tracker.models.length - 1,
      :number_of_templates => number_of_templates(@tracker),
      :ruby_version => RUBY_VERSION,
      :brakeman_version => Brakeman::Version
    }

    report_info = {
      :scan_info => scan_info,
      :warnings => warnings,
      :errors => errors
    }

    MultiJson.dump(report_info, :pretty => true)
  end

  def all_warnings
    @all_warnings ||= @checks.all_warnings
  end

  def number_of_templates tracker
    Set.new(tracker.templates.map {|k,v| v[:name].to_s[/[^.]+/]}).length
  end

  def warning_file warning, relative = false
    return nil if warning.file.nil?

    if @tracker.options[:relative_paths] or relative
      relative_path warning.file
    else
      warning.file
    end
  end

end
