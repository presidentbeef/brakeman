require 'cgi'
require 'set'
require 'processors/output_processor'
require 'util'

#Generates a report based on the Tracker and the results of
#Tracker#run_checks. Be sure to +run_checks+ before generating
#a report.
class Report
  include Util

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
  def generate_overview
    templates = Set.new(@tracker.templates.map {|k,v| v[:name].to_s[/[^.]+/]}).length
    warnings = checks.warnings.length +
                checks.controller_warnings.length +
                checks.model_warnings.length +
                checks.template_warnings.length

    #Add number of high confidence warnings in summary.
    #Skipping for CSV because it makes the cell text instead of
    #a number.
    unless OPTIONS[:output_format] == :to_csv
      summary = warnings_summary

      if OPTIONS[:output_format] == :to_html
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
  def generate_errors
    unless tracker.errors.empty?
      table = Ruport::Data::Table(["Error", "Location"])
      tracker.errors.each do |w|
        p w if OPTIONS[:debug]
        table << { "Error" => w[:error], "Location" => w[:backtrace][0] }
      end

      table
    else
      nil
    end
  end

  #Generate table of general security warnings
  def generate_warnings
    table = Ruport::Data::Table(["Confidence", "Class", "Method", "Warning Type", "Message"])
    checks.warnings.each do |warning|
      next if warning.confidence > OPTIONS[:min_confidence]
      w = warning.to_row

      if OPTIONS[:output_format] == :to_html
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
  def generate_template_warnings
    unless checks.template_warnings.empty?
      table = Ruport::Data::Table(["Confidence", "Template", "Warning Type", "Message"])
      checks.template_warnings.each do |warning|
        next if warning.confidence > OPTIONS[:min_confidence]
        w = warning.to_row :template

        if OPTIONS[:output_format] == :to_html
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
  def generate_model_warnings
    unless checks.model_warnings.empty?
      table = Ruport::Data::Table(["Confidence", "Model", "Warning Type", "Message"])
      checks.model_warnings.each do |warning|
        next if warning.confidence > OPTIONS[:min_confidence]
        w = warning.to_row :model

        if OPTIONS[:output_format] == :to_html
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
  def generate_controller_warnings
    unless checks.controller_warnings.empty?
      table = Ruport::Data::Table(["Confidence", "Controller", "Warning Type", "Message"])
      checks.controller_warnings.each do |warning|
        next if warning.confidence > OPTIONS[:min_confidence]
        w = warning.to_row :controller

        if OPTIONS[:output_format] == :to_html
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
  def generate_templates
    out_processor = OutputProcessor.new
    table = Ruport::Data::Table(["Name", "Output"])
    tracker.templates.each do |name, template|
      unless template[:outputs].empty?
        template[:outputs].each do |out|
          out = out_processor.format out
          out = CGI.escapeHTML(out) if OPTIONS[:output_format] == :to_html
          table << { "Name" => name,
            "Output" => out.gsub("\n", ";").gsub(/\s+/, " ") }
        end
      end
    end
    Ruport::Data::Grouping(table, :by => "Name")
  end

  #Generate HTML output
  def to_html
    load_ruport

    out = html_header <<
    "<h2 id='summary'>Summary</h2>" <<
    generate_overview.to_html << "<br/>" <<
    generate_warning_overview.to_html

    if OPTIONS[:report_routes] or OPTIONS[:debug]
      out << "<h2>Controllers</h2>" <<
      generate_controllers.to_html
    end

    if OPTIONS[:debug]
      out << "<h2>Templates</h2>" <<
      generate_templates.to_html
    end

    res = generate_errors
    out << "<h2>Errors</h2>" << res.to_html if res

    res = generate_warnings
    out << "<h2>Security Warnings</h2>" << res.to_html if res

    res = generate_controller_warnings
    out << res.to_html if res

    res = generate_model_warnings 
    out << res.to_html if res

    res = generate_template_warnings
    out << res.to_html if res

    out << "</body></html>"
  end

  #Output text version of the report
  def to_s
    load_ruport

    out = text_header <<
    "\n+SUMMARY+\n" <<
    generate_overview.to_s << "\n" <<
    generate_warning_overview.to_s << "\n"

    if OPTIONS[:report_routes] or OPTIONS[:debug]
      out << "+CONTROLLERS+\n" <<
      generate_controllers.to_s << "\n"
    end

    if OPTIONS[:debug]
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
    load_ruport

    out = csv_header <<
    "\nSUMMARY\n" <<
    generate_overview.to_csv << "\n" <<
    generate_warning_overview.to_csv << "\n"

    if OPTIONS[:report_routes] or OPTIONS[:debug]
      out << "CONTROLLERS\n" <<
      generate_controllers.to_csv << "\n"
    end

    if OPTIONS[:debug]
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

  #Return header for HTML output. Uses CSS from OPTIONS[:html_style]
  def html_header
    if File.exist? OPTIONS[:html_style]
      css = File.read OPTIONS[:html_style]
    else
      raise "Cannot find CSS stylesheet for HTML: #{OPTIONS[:html_style]}"
    end

    <<-HTML
    <!DOCTYPE HTML SYSTEM>
    <html>
    <head>
    <title>Brakeman Report</title>
    <script type="text/javascript">
      function toggle(context){
        if (document.getElementById(context).style.display != "block")
          document.getElementById(context).style.display = "block";
        else
          document.getElementById(context).style.display = "none";
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
        <th>Report Generation Time</th>
        <th>Checks Performed</th>
      </tr>
      <tr>
        <td>#{File.expand_path OPTIONS[:app_path]}</td>
        <td>#{Time.now}</td>
        <td>#{checks.checks_run.sort.join(", ")}</td>
      </tr>
     </table>
    HTML
  end

  #Generate header for text output
  def text_header
    "\n+BRAKEMAN REPORT+\n\nApplication path: #{File.expand_path OPTIONS[:app_path]}\nGenerated at #{Time.now}\nChecks run: #{checks.checks_run.sort.join(", ")}\n"
  end

  #Generate header for CSV output
  def csv_header
    header = Ruport::Data::Table(["Application Path", "Report Generation Time", "Checks Performed"])
    header << [File.expand_path(OPTIONS[:app_path]), Time.now.to_s, checks.checks_run.sort.join(", ")]
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
        summary[warning.warning_type.to_s] += 1

        if warning.confidence == 0
          high_confidence_warnings += 1
        end
      end
    end

    summary[:high_confidence] = high_confidence_warnings
    @warnings_summary = summary
  end

  #Return file name related to given warning. Uses +warning.file+ if it exists
  def file_for warning
    if warning.file
      File.expand_path warning.file, OPTIONS[:app_path]
    else
      case warning.warning_set
      when :controller
        file_by_name warning.controller, :controller
      when :template
        file_by_name warning.template[:name], :template
      when :model
        file_by_name warning.model, :model
      when :warning
        file_by_name warning.class
      else
        nil
      end
    end
  end

  #Attempt to determine path to context file based on the reported name
  #in the warning.
  #
  #For example,
  #
  #  file_by_name FileController #=> "/rails/root/app/controllers/file_controller.rb
  def file_by_name name, type = nil
    return nil unless name
    string_name = name.to_s
    name = name.to_sym

    unless type
      if string_name =~ /Controller$/
        type = :controller
      elsif camelize(string_name) == string_name
        type = :model
      else
        type = :template
      end
    end

    path = OPTIONS[:app_path]

    case type
    when :controller
      if tracker.controllers[name] and tracker.controllers[name][:file]
        path = tracker.controllers[name][:file]
      else
        path += "/app/controllers/#{underscore(string_name)}.rb"
      end
    when :model
      if tracker.models[name] and tracker.models[name][:file]
        path = tracker.models[name][:file]
      else
        path += "/app/controllers/#{underscore(string_name)}.rb"
      end
    when :template
      if tracker.templates[name] and tracker.templates[name][:file]
        path = tracker.templates[name][:file]
      elsif string_name.include? " "
        name = string_name.split[0].to_sym
        path = file_for name, :template
      else
        path = nil
      end
    end

    path
  end

  #Return array of lines surrounding the warning location from the original
  #file.
  def context_for warning
    file = file_for warning
    context = []
    return context unless warning.line and file and File.exist? file

    current_line = 0
    start_line = warning.line - 5
    end_line = warning.line + 5

    start_line = 1 if start_line < 0

    File.open file do |f|
      f.each_line do |line|
        current_line += 1

        next if line.strip == ""

        if current_line > end_line
          break
        end

        if current_line >= start_line
          context << [current_line, line]
        end
      end
    end

    context
  end

  #Generate HTML for warnings, including context show/hidden via Javascript
  def with_context warning, message
    context = context_for warning
    full_message = nil

    if OPTIONS[:message_limit] and
      OPTIONS[:message_limit] > 0 and 
      message.length > OPTIONS[:message_limit]

      full_message = message
      message = message[0..OPTIONS[:message_limit]] << "..."
    end

    if context.empty?
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

  def to_tabs
    [[:warnings, "General"], [:controller_warnings, "Controller"],
      [:model_warnings, "Model"], [:template_warnings, "Template"]].map do |meth, category|

      checks.send(meth).map do |w|
        line = w.line || 0
        "#{file_for w}\t#{line}\t#{w.warning_type}\t#{category}\t#{w.format_message}\t#{TEXT_CONFIDENCE[w.confidence]}"
      end.join "\n"

    end.join "\n"
  end

  def load_ruport
    require 'ruport'
  rescue LoadError => e
    $stderr.puts e
    $stderr.puts "Please install Ruport."
    exit!
  end
end
