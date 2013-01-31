require 'cgi'
require 'set'
require 'pathname'
require 'brakeman/processors/output_processor'
require 'brakeman/util'
require 'terminal-table'
require 'highline/system_extensions'
require "csv"
require 'multi_json'
require 'brakeman/version'

if CSV.const_defined? :Reader
  # Ruby 1.8 compatible
  require 'fastercsv'
  Object.send(:remove_const, :CSV)
  CSV = FasterCSV
else
  # CSV is now FasterCSV in ruby 1.9
end

#MultiJson interface changed in 1.3.0, but need
#to support older MultiJson for Rails 3.1.
if MultiJson.respond_to? :default_adapter
  mj_engine = MultiJson.default_adapter
else
  mj_engine = MultiJson.default_engine

  module MultiJson
    def self.dump *args
      encode *args
    end

    def self.load *args
      decode *args
    end
  end
end

#This is so OkJson will work with symbol values
if mj_engine == :ok_json
  class Symbol
    def to_json
      self.to_s.inspect
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

  def initialize(app_tree, tracker)
    @app_tree = app_tree
    @tracker = tracker
    @checks = tracker.checks
    @element_id = 0 #Used for HTML ids
    @warnings_summary = nil
    @highlight_user_input = tracker.options[:highlight_user_input]
  end

  #Generate summary table of what was parsed
  def generate_overview html = false
    warnings = all_warnings.length

    if html
      load_and_render_erb('overview', binding)
    else
      Terminal::Table.new(:headings => ['Scanned/Reported', 'Total']) do |t|
        t.add_row ['Controllers', tracker.controllers.length]
        t.add_row ['Models', tracker.models.length - 1]
        t.add_row ['Templates', number_of_templates(@tracker)]
        t.add_row ['Errors', tracker.errors.length]
        t.add_row ['Security Warnings', "#{warnings} (#{warnings_summary[:high_confidence]})"]
      end
    end
  end

  #Generate table of how many warnings of each warning type were reported
  def generate_warning_overview html = false
    types = warnings_summary.keys
    types.delete :high_confidence

    if html
      load_and_render_erb('warning_overview', binding)
    else
      Terminal::Table.new(:headings => ['Warning Type', 'Total']) do |t|
        types.sort.each do |warning_type|
          t.add_row [warning_type, warnings_summary[warning_type]]
        end
      end
    end
  end

  #Generate table of errors or return nil if no errors
  def generate_errors html = false
    if tracker.errors.any?
      if html
        load_and_render_erb('error_overview', binding)
      else
        Terminal::Table.new(:headings => ['Error', 'Location']) do |t|
          tracker.errors.each do |error|
            t.add_row [error[:error], error[:backtrace][0]]
          end
        end
      end
    else
      nil
    end
  end

  #Generate table of general security warnings
  def generate_warnings html = false
    warning_messages = []
    checks.warnings.each do |warning|
      w = warning.to_row

      if html
        w["Confidence"] = HTML_CONFIDENCE[w["Confidence"]]
        w["Message"] = with_context warning, w["Message"]
        w["Warning Type"] = with_link warning, w["Warning Type"]
      else
        w["Confidence"] = TEXT_CONFIDENCE[w["Confidence"]]
        w["Message"] = text_message warning, w["Message"]
      end

      warning_messages << w
    end

    stabilizer = 0
    warning_messages = warning_messages.sort_by{|row| stabilizer += 1; [row['Confidence'], row['Warning Type'], row['Class'], stabilizer]}

    if html
      load_and_render_erb('security_warnings', binding)
    else
      if warning_messages.empty?
        Terminal::Table.new(:headings => ['General Warnings']) do |t|
          t.add_row ['[NONE]']
        end
      else
        Terminal::Table.new(:headings => ["Confidence", "Class", "Method", "Warning Type", "Message"]) do |t|
          warning_messages.each do |row|
            t.add_row [row["Confidence"], row["Class"], row["Method"], row["Warning Type"], row["Message"]]
          end
        end
      end
    end
  end

  #Generate table of template warnings or return nil if no warnings
  def generate_template_warnings html = false
    if checks.template_warnings.any?
      warnings = []
      checks.template_warnings.each do |warning|
        w = warning.to_row :template

        if html
          w["Confidence"] = HTML_CONFIDENCE[w["Confidence"]]
          w["Message"] = with_context warning, w["Message"]
          w["Warning Type"] = with_link warning, w["Warning Type"]
          w["Called From"] = warning.called_from
          w["Template Name"] = warning.template[:name]
        else
          w["Confidence"] = TEXT_CONFIDENCE[w["Confidence"]]
          w["Message"] = text_message warning, w["Message"]
        end

        warnings << w
      end

      return nil if warnings.empty?

      stabilizer = 0
      warnings = warnings.sort_by{|row| stabilizer += 1; [row["Confidence"], row["Warning Type"], row["Template"], stabilizer]}
      if html
        load_and_render_erb('view_warnings', binding)
      else
        Terminal::Table.new(:headings => ["Confidence", "Template", "Warning Type", "Message"]) do |t|
          warnings.each do |warning|
            t.add_row [warning["Confidence"], warning["Template"], warning["Warning Type"], warning["Message"]]
          end
        end
      end
    else
      nil
    end
  end

  #Generate table of model warnings or return nil if no warnings
  def generate_model_warnings html = false
    if checks.model_warnings.any?
      warnings = []
      checks.model_warnings.each do |warning|
        w = warning.to_row :model

        if html
          w["Confidence"] = HTML_CONFIDENCE[w["Confidence"]]
          w["Message"] = with_context warning, w["Message"]
          w["Warning Type"] = with_link warning, w["Warning Type"]
        else
          w["Confidence"] = TEXT_CONFIDENCE[w["Confidence"]]
          w["Message"] = text_message warning, w["Message"]
        end

        warnings << w
      end

      return nil if warnings.empty?
      stabilizer = 0
      warnings = warnings.sort_by{|row| stabilizer +=1; [row["Confidence"],row["Warning Type"], row["Model"], stabilizer]}

      if html
        load_and_render_erb('model_warnings', binding)
      else
        Terminal::Table.new(:headings => ["Confidence", "Model", "Warning Type", "Message"]) do |t|
          warnings.each do |warning|
            t.add_row [warning["Confidence"], warning["Model"], warning["Warning Type"], warning["Message"]]
          end
        end
      end
    else
      nil
    end
  end

  #Generate table of controller warnings or nil if no warnings
  def generate_controller_warnings html = false
    unless checks.controller_warnings.empty?
      warnings = []
      checks.controller_warnings.each do |warning|
        w = warning.to_row :controller

        if html
          w["Confidence"] = HTML_CONFIDENCE[w["Confidence"]]
          w["Message"] = with_context warning, w["Message"]
          w["Warning Type"] = with_link warning, w["Warning Type"]
        else
          w["Confidence"] = TEXT_CONFIDENCE[w["Confidence"]]
          w["Message"] = text_message warning, w["Message"]
        end

        warnings << w
      end

      return nil if warnings.empty?

      stabilizer = 0
      warnings = warnings.sort_by{|row| stabilizer +=1; [row["Confidence"], row["Warning Type"], row["Controller"], stabilizer]}

      if html
        load_and_render_erb('controller_warnings', binding)
      else
        Terminal::Table.new(:headings => ["Confidence", "Controller", "Warning Type", "Message"]) do |t|
          warnings.each do |warning|
            t.add_row [warning["Confidence"], warning["Controller"], warning["Warning Type"], warning["Message"]]
          end
        end
      end
    else
      nil
    end
  end

  #Generate table of controllers and routes found for those controllers
  def generate_controllers html=false
    controller_rows = []
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

      controller_rows << { "Name" => name.to_s,
        "Parent" => c[:parent].to_s,
        "Includes" => c[:includes].join(", "),
        "Routes" => routes
      }
    end
    controller_rows = controller_rows.sort_by{|row| row['Name']}

    if html
      load_and_render_erb('controller_overview', binding)
    else
      Terminal::Table.new(:headings => ['Name', 'Parent', 'Includes', 'Routes']) do |t|
        controller_rows.each do |row|
          t.add_row [row['Name'], row['Parent'], row['Includes'], row['Routes']]
        end
      end
    end
  end

  #Generate listings of templates and their output
  def generate_templates html = false
    out_processor = Brakeman::OutputProcessor.new
    template_rows = {}
    tracker.templates.each do |name, template|
      unless template[:outputs].empty?
        template[:outputs].each do |out|
          out = out_processor.format out
          out = CGI.escapeHTML(out) if html
          template_rows[name] ||= []
          template_rows[name] << out.gsub("\n", ";").gsub(/\s+/, " ")
        end
      end
    end

    template_rows = template_rows.sort_by{|name, value| name.to_s}

    if html
      load_and_render_erb('template_overview', binding)
    else
      output = ''
      template_rows.each do |template|
        output << template.first.to_s << "\n\n"
        table = Terminal::Table.new(:headings => ['Output']) do |t|
          # template[1] is an array of calls
          template[1].each do |v|
            t.add_row [v]
          end
        end

        output << table.to_s << "\n\n"
      end

      output
    end
  end

  #Generate HTML output
  def to_html
    out = html_header <<
    generate_overview(true) <<
    generate_warning_overview(true)

    # Return early if only summarizing
    if tracker.options[:summary_only]
      return out
    end

    if tracker.options[:report_routes] or tracker.options[:debug]
      out << generate_controllers(true).to_s
    end

    if tracker.options[:debug]
      out << generate_templates(true).to_s
    end

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
    if tracker.options[:summary_only]
      return out
    end

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

    load_and_render_erb('header', binding)
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

        if warning.confidence == 0
          high_confidence_warnings += 1
        end
      end
    end

    summary[:high_confidence] = high_confidence_warnings
    @warnings_summary = summary
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

  #Escape warning message and highlight user input in HTML output
  def html_message warning, message
    message = CGI.escapeHTML(message)

    if @highlight_user_input and warning.user_input
      user_input = CGI.escapeHTML(warning.format_user_input)

      message.gsub!(user_input, "<span class=\"user_input\">#{user_input}</span>")
    end

    message
  end

  #Generate HTML for warnings, including context show/hidden via Javascript
  def with_context warning, message
    context = context_for(@app_tree, warning)
    full_message = nil

    if tracker.options[:message_limit] and
      tracker.options[:message_limit] > 0 and
      message.length > tracker.options[:message_limit]

      full_message = html_message(warning, message)
      message = message[0..tracker.options[:message_limit]] << "..."
    end

    message = html_message(warning, message)

    if context.empty? and not full_message
      return message
    end

    @element_id += 1
    code_id = "context#@element_id"
    message_id = "message#@element_id"
    full_message_id = "full_message#@element_id"
    alt = false
    output = "<div class='warning_message' onClick=\"toggle('#{code_id}');toggle('#{message_id}');toggle('#{full_message_id}')\" >" <<
    if full_message
      "<span id='#{message_id}' style='display:block' >#{message}</span>" <<
      "<span id='#{full_message_id}' style='display:none'>#{full_message}</span>"
    else
      message
    end <<
    "<table id='#{code_id}' class='context' style='display:none'>" <<
    "<caption>#{warning_file(warning, :relative) || ''}</caption>"

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

  def with_link warning, message
    "<a href=\"#{warning.link}\">#{message}</a>"
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
      Pathname.new(warning.file).relative_path_from(Pathname.new(tracker.options[:app_path])).to_s
    else
      warning.file
    end
  end

  private

  def load_and_render_erb file, bind
    content = File.read(File.expand_path("templates/#{file}.html.erb", File.dirname(__FILE__)))
    template = ERB.new(content)
    template.result(bind)
  end
end
