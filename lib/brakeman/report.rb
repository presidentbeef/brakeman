require 'cgi'
require 'set'
require 'ruport'
require 'brakeman/processors/output_processor'
require 'brakeman/util'

#Fix for Ruport under 1.9
#as reported here: https://github.com/ruport/ruport/pull/7
module Ruport
  class Formatter::CSV < Formatter
    def csv_writer
      @csv_writer ||= options.formatter ||
        FCSV.instance(output, options.format_options || {})
    end
  end
end

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

  def initialize tracker
    @tracker = tracker
    @checks = tracker.checks
    @element_id = 0 #Used for HTML ids
    @warnings_summary = nil
  end

  #Generate summary table of what was parsed
  def generate_overview html = false
    templates = Set.new(@tracker.templates.map {|k,v| v[:name].to_s[/[^.]+/]}).length
    warnings = checks.warnings.length +
                checks.controller_warnings.length +
                checks.model_warnings.length +
                checks.template_warnings.length

    #Add number of high confidence warnings in summary.
    #Skipping for CSV because it makes the cell text instead of
    #a number.
    unless tracker.options[:output_format] == :to_csv
      summary = warnings_summary

      if html
        warnings = "#{warnings} <span class='high-confidence'>(#{summary[:high_confidence]})</span>"
      else
        warnings = "#{warnings} (#{summary[:high_confidence]})"
      end
    end

    table = Ruport::Data::Table(["Scanned/Reported", "Total"])
    table << { "Scanned/Reported" => "Controllers", "Total" => tracker.controllers.length }
    #One less because of the 'fake' one used for unknown models
    table << { "Scanned/Reported" => "Models", "Total" => tracker.models.length - 1 }
    table << { "Scanned/Reported" => "Templates", "Total" => templates }
    table << { "Scanned/Reported" => "Errors", "Total" => tracker.errors.length }
    table << { "Scanned/Reported" => "Security Warnings", "Total" => warnings}
  end

  #Generate table of how many warnings of each warning type were reported
  def generate_warning_overview
    table = Ruport::Data::Table(["Warning Type", "Total"])
    types = warnings_summary.keys
    types.delete :high_confidence
    types.sort.each do |warning_type|
      table << { "Warning Type" => warning_type, "Total" => warnings_summary[warning_type] }
    end
    table
  end

  #Generate table of errors or return nil if no errors
  def generate_errors html = false
    unless tracker.errors.empty?
      table = Ruport::Data::Table(["Error", "Location"])
      
     
      tracker.errors.each do |w|
        Brakeman.debug w.inspect

        if html
          w[:error] = CGI.escapeHTML w[:error]
        end

        table << { "Error" => w[:error], "Location" => w[:backtrace][0] }
      end

      table
    else
      nil
    end
  end

  #Generate table of general security warnings
  def generate_warnings html = false
    table = Ruport::Data::Table(["Confidence", "Class", "Method", "Warning Type", "Message"])
    checks.warnings.each do |warning|
      next if warning.confidence > tracker.options[:min_confidence]
      w = warning.to_row

      if html
        w["Confidence"] = HTML_CONFIDENCE[w["Confidence"]]
        w["Message"] = with_context warning, w["Message"]
      else
        w["Confidence"] = TEXT_CONFIDENCE[w["Confidence"]]
      end

      table << w
    end

    table.sort_rows_by! "Class"
    table.sort_rows_by! "Warning Type"
    table.sort_rows_by! "Confidence"

    if table.empty?
      table = Ruport::Data::Table("General Warnings")
      table << { "General Warnings" => "[NONE]" }
    end

    table
  end

  #Generate table of template warnings or return nil if no warnings
  def generate_template_warnings html = false
    unless checks.template_warnings.empty?
      table = Ruport::Data::Table(["Confidence", "Template", "Warning Type", "Message"])
      checks.template_warnings.each do |warning|
        next if warning.confidence > tracker.options[:min_confidence]
        w = warning.to_row :template

        if html
          w["Confidence"] = HTML_CONFIDENCE[w["Confidence"]]
          w["Message"] = with_context warning, w["Message"]
        else
          w["Confidence"] = TEXT_CONFIDENCE[w["Confidence"]]
        end

        table << w
      end

      if table.empty?
        nil
      else
        table.sort_rows_by! "Template"
        table.sort_rows_by! "Warning Type"
        table.sort_rows_by! "Confidence"
        table.to_group "View Warnings"
      end
    else
      nil
    end
  end

  #Generate table of model warnings or return nil if no warnings
  def generate_model_warnings html = false
    unless checks.model_warnings.empty?
      table = Ruport::Data::Table(["Confidence", "Model", "Warning Type", "Message"])
      checks.model_warnings.each do |warning|
        next if warning.confidence > tracker.options[:min_confidence]
        w = warning.to_row :model

        if html
          w["Confidence"] = HTML_CONFIDENCE[w["Confidence"]]
          w["Message"] = with_context warning, w["Message"]
        else
          w["Confidence"] = TEXT_CONFIDENCE[w["Confidence"]]
        end

        table << w
      end

      if table.empty?
        nil
      else
        table.sort_rows_by! "Model"
        table.sort_rows_by! "Warning Type"
        table.sort_rows_by! "Confidence"
        table.to_group "Model Warnings"
      end
    else
      nil
    end
  end

  #Generate table of controller warnings or nil if no warnings
  def generate_controller_warnings html = false
    unless checks.controller_warnings.empty?
      table = Ruport::Data::Table(["Confidence", "Controller", "Warning Type", "Message"])
      checks.controller_warnings.each do |warning|
        next if warning.confidence > tracker.options[:min_confidence]
        w = warning.to_row :controller

        if html
          w["Confidence"] = HTML_CONFIDENCE[w["Confidence"]]
          w["Message"] = with_context warning, w["Message"]
        else
          w["Confidence"] = TEXT_CONFIDENCE[w["Confidence"]]
        end

        table << w
      end

      if table.empty?
        nil
      else
        table.sort_rows_by! "Controller"
        table.sort_rows_by! "Warning Type"
        table.sort_rows_by! "Confidence"
        table.to_group "Controller Warnings"
      end
    else
      nil
    end
  end

  #Generate table of controllers and routes found for those controllers
  def generate_controllers
    table = Ruport::Data::Table(["Name", "Parent", "Includes", "Routes"])
    tracker.controllers.keys.map{|k| k.to_s}.sort.each do |name|
      name = name.to_sym
      c = tracker.controllers[name]

      if tracker.routes[:allow_all_actions] or tracker.routes[name] == :allow_all_actions
        routes = c[:public].keys.map{|e| e.to_s}.sort.join(", ")
      elsif tracker.routes[name].nil?
        #No routes defined for this controller.
        #This can happen when it is only a parent class
        #for other controllers, for example.
        routes = "[None]"

      else
        routes = (Set.new(c[:public].keys) & tracker.routes[name.to_sym]).
          to_a.
          map {|e| e.to_s}.
          sort.
          join(", ")
      end

      if routes == ""
        routes = "[None]"
      end

      table << { "Name" => name.to_s,
        "Parent" => c[:parent].to_s,
        "Includes" => c[:includes].join(", "),
        "Routes" => routes
      }
    end
    table.sort_rows_by "Name"
  end

  #Generate listings of templates and their output
  def generate_templates html = false
    out_processor = Brakeman::OutputProcessor.new
    table = Ruport::Data::Table(["Name", "Output"])
    tracker.templates.each do |name, template|
      unless template[:outputs].empty?
        template[:outputs].each do |out|
          out = out_processor.format out
          out = CGI.escapeHTML(out) if html
          table << { "Name" => name,
            "Output" => out.gsub("\n", ";").gsub(/\s+/, " ") }
        end
      end
    end
    Ruport::Data::Grouping(table, :by => "Name")
  end

  #Generate HTML output
  def to_html
    out = html_header <<
    "<h2 id='summary'>Summary</h2>" <<
    generate_overview(true).to_html << "<br/>" <<
    generate_warning_overview.to_html

    #Return early if only summarizing
    if tracker.options[:summary_only]
      return out
    end

    if tracker.options[:report_routes] or tracker.options[:debug]
      out << "<h2>Controllers</h2>" <<
      generate_controllers.to_html
    end

    if tracker.options[:debug]
      out << "<h2>Templates</h2>" <<
      generate_templates(true).to_html
    end

    res = generate_errors(true)
    if res
        out << "<div onClick=\"toggle('errors_table');\">  <h2>Exceptions raised during the analysis (click to see them)</h2 ></div> <div id='errors_table' style='display:none'>" << res.to_html << '</div>'
    end

    res = generate_warnings(true)
    out << "<h2>Security Warnings</h2>" << res.to_html if res

    res = generate_controller_warnings(true)
    out << res.to_html if res

    res = generate_model_warnings(true)
    out << res.to_html if res

    res = generate_template_warnings(true)
    out << res.to_html if res

    out << "</body></html>"
  end

  #Output text version of the report
  def to_s
    out = text_header <<
    "\n+SUMMARY+\n" <<
    generate_overview.to_s << "\n" <<
    generate_warning_overview.to_s << "\n"

    #Return output early if only summarizing
    if tracker.options[:summary_only]
      return out
    end

    if tracker.options[:report_routes] or tracker.options[:debug]
      out << "+CONTROLLERS+\n" <<
      generate_controllers.to_s << "\n"
    end

    if tracker.options[:debug]
      out << "+TEMPLATES+\n\n" <<
      generate_templates.to_s << "\n"
    end

    res = generate_errors
    out << "+ERRORS+\n" << res.to_s << "\n" if res

    res = generate_warnings
    out << "+SECURITY WARNINGS+\n" << res.to_s << "\n" if res

    res = generate_controller_warnings
    out << res.to_s << "\n" if res

    res = generate_model_warnings 
    out << res.to_s << "\n" if res

    res = generate_template_warnings
    out << res.to_s << "\n" if res

    out
  end

  #Generate CSV output
  def to_csv
    out = csv_header <<
    "\nSUMMARY\n" <<
    generate_overview.to_csv << "\n" <<
    generate_warning_overview.to_csv << "\n"

    #Return output early if only summarizing
    if tracker.options[:summary_only]
      return out
    end

    if tracker.options[:report_routes] or tracker.options[:debug]
      out << "CONTROLLERS\n" <<
      generate_controllers.to_csv << "\n"
    end

    if tracker.options[:debug]
      out << "TEMPLATES\n\n" <<
      generate_templates.to_csv << "\n"
    end

    res = generate_errors
    out << "ERRORS\n" << res.to_csv << "\n" if res

    res = generate_warnings
    out << "SECURITY WARNINGS\n" << res.to_csv << "\n" if res

    res = generate_controller_warnings
    out << res.to_csv << "\n" if res

    res = generate_model_warnings 
    out << res.to_csv << "\n" if res

    res = generate_template_warnings
    out << res.to_csv << "\n" if res

    out
  end

  #Not yet implemented
  def to_pdf
    raise "PDF output is not yet supported."
  end

  def rails_version
    if version = tracker.config[:rails_version]
      return version
    elsif tracker.options[:rails3]
      return "3.x"
    else
      return "Unknown"
    end
  end

  #Return header for HTML output. Uses CSS from tracker.options[:html_style]
  def html_header
    if File.exist? tracker.options[:html_style]
      css = File.read tracker.options[:html_style]
    else
      raise "Cannot find CSS stylesheet for HTML: #{tracker.options[:html_style]}"
    end

    <<-HTML
    <!DOCTYPE HTML SYSTEM>
    <html>
    <head>
    <title>Brakeman Report</title>
    <script type="text/javascript">
      function toggle(context) {
        var elem = document.getElementById(context);

        if (elem.style.display != "block")
          elem.style.display = "block";
        else
          elem.style.display = "none";
          
        elem.parentNode.scrollIntoView();
      }
    </script>
    <style type="text/css"> 
    #{css}
    </style>
    </head>
    <body>
    <h1>Brakeman Report</h1>
    <table>
      <tr>
        <th>Application Path</th>
        <th>Rails Version</th>
        <th>Report Generation Time</th>
        <th>Checks Performed</th>
      </tr>
      <tr>
        <td>#{File.expand_path tracker.options[:app_path]}</td>
        <td>#{rails_version}</td>
        <td>#{Time.now}</td>
        <td>#{checks.checks_run.sort.join(", ")}</td>
      </tr>
     </table>
    HTML
  end

  #Generate header for text output
  def text_header
    "\n+BRAKEMAN REPORT+\n\nApplication path: #{File.expand_path tracker.options[:app_path]}\nRails version: #{rails_version}\nGenerated at #{Time.now}\nChecks run: #{checks.checks_run.sort.join(", ")}\n"
  end

  #Generate header for CSV output
  def csv_header
    header = Ruport::Data::Table(["Application Path", "Report Generation Time", "Checks Performed", "Rails Version"])
    header << [File.expand_path(tracker.options[:app_path]), Time.now.to_s, checks.checks_run.sort.join(", "), rails_version]
    "BRAKEMAN REPORT\n\n" << header.to_csv
  end

  #Return summary of warnings in hash and store in @warnings_summary
  def warnings_summary
    return @warnings_summary if @warnings_summary

    summary = Hash.new(0)
    high_confidence_warnings = 0

    [checks.warnings, 
        checks.controller_warnings, 
        checks.model_warnings, 
        checks.template_warnings].each do |warnings|

      warnings.each do |warning|
        unless warning.confidence > tracker.options[:min_confidence]

          summary[warning.warning_type.to_s] += 1

          if warning.confidence == 0
            high_confidence_warnings += 1
          end
        end
      end
    end

    summary[:high_confidence] = high_confidence_warnings
    @warnings_summary = summary
  end


  #Generate HTML for warnings, including context show/hidden via Javascript
  def with_context warning, message
    context = context_for warning
    full_message = nil

    if tracker.options[:message_limit] and
      tracker.options[:message_limit] > 0 and 
      message.length > tracker.options[:message_limit]

      full_message = message
      message = message[0..tracker.options[:message_limit]] << "..."
    end

    if context.empty? and not full_message
      return CGI.escapeHTML(message)
    end

    @element_id += 1
    code_id = "context#@element_id"
    message_id = "message#@element_id"
    full_message_id = "full_message#@element_id"
    alt = false
    output = "<div class='warning_message' onClick=\"toggle('#{code_id}');toggle('#{message_id}');toggle('#{full_message_id}')\" >" <<
    if full_message
      "<span id='#{message_id}' style='display:block' >#{CGI.escapeHTML(message)}</span>" <<
      "<span id='#{full_message_id}' style='display:none'>#{CGI.escapeHTML(full_message)}</span>"
    else
      CGI.escapeHTML(message)
    end <<
    "<table id='#{code_id}' class='context' style='display:none'>"

    unless context.empty?
      if warning.line - 1 == 1 or warning.line + 1 == 1
        error = " near_error"
      elsif 1 == warning.line
        error = " error"
      else
        error = ""
      end

      output << <<-HTML
        <tr class='context first#{error}'>
          <td class='context_line'>
            <pre class='context'>#{context.first[0]}</pre>
          </td>
          <td class='context'>
            <pre class='context'>#{CGI.escapeHTML context.first[1].chomp}</pre>
          </td>
        </tr>
      HTML

      if context.length > 1
        output << context[1..-1].map do |code|
          alt = !alt
          if code[0] == warning.line - 1 or code[0] == warning.line + 1
            error = " near_error"
          elsif code[0] == warning.line
            error = " error"
          else
            error = ""
          end

          <<-HTML
          <tr class='context#{alt ? ' alt' : ''}#{error}'>
            <td class='context_line'>
              <pre class='context'>#{code[0]}</pre>
            </td>
            <td class='context'>
              <pre class='context'>#{CGI.escapeHTML code[1].chomp}</pre>
            </td>
          </tr>
          HTML
        end.join
      end
    end

    output << "</table></div>"
  end

  #Generated tab-separated output suitable for the Jenkins Brakeman Plugin:
  #https://github.com/presidentbeef/brakeman-jenkins-plugin
  def to_tabs
    [[:warnings, "General"], [:controller_warnings, "Controller"],
      [:model_warnings, "Model"], [:template_warnings, "Template"]].map do |meth, category|

      checks.send(meth).map do |w|
        next if w.confidence > tracker.options[:min_confidence]
        line = w.line || 0
        w.warning_type.gsub!(/[^\w\s]/, ' ')
        "#{file_for w}\t#{line}\t#{w.warning_type}\t#{category}\t#{w.format_message}\t#{TEXT_CONFIDENCE[w.confidence]}"
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
        w.context = context_for(w).join("\n")
        w.file = file_for w
      end
    end
      
    report
  end
end
