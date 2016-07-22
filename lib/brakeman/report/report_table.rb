Brakeman.load_brakeman_dependency 'terminal-table'

class Brakeman::Report::Table < Brakeman::Report::Base
  def initialize *args
    super
    @table = Terminal::Table
  end

  def generate_report
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

    output_table("+Errors+", generate_errors, out)
    output_table("+SECURITY WARNINGS+", generate_warnings, out)
    output_table("Controller Warnings:", generate_controller_warnings, out)
    output_table("Model Warnings:", generate_model_warnings, out)
    output_table("View Warnings:", generate_template_warnings, out)

    out << "\n"
    out
  end

  def output_table title, result, output
    return unless result

    output << "\n\n#{title}\n\n#{truncate_table(result.to_s)}"
  end

  def generate_overview
    num_warnings = all_warnings.length

    @table.new(:headings => ['Scanned/Reported', 'Total']) do |t|
      t.add_row ['Controllers', tracker.controllers.length]
      t.add_row ['Models', tracker.models.length - 1]
      t.add_row ['Templates', number_of_templates(@tracker)]
      t.add_row ['Errors', tracker.errors.length]
      t.add_row ['Security Warnings', "#{num_warnings} (#{warnings_summary[:high_confidence]})"]
      t.add_row ['Ignored Warnings', ignored_warnings.length] unless ignored_warnings.empty?
    end
  end

  def render_array template, headings, value_array, locals
    return if value_array.empty?

    @table.new(:headings => headings) do |t|
      value_array.each { |value_row| t.add_row value_row }
    end
  end

  #Generate header for text output
  def text_header
    <<-HEADER

+BRAKEMAN REPORT+

Application path: #{tracker.app_path}
Rails version: #{rails_version}
Brakeman version: #{Brakeman::Version}
Started at #{tracker.start_time}
Duration: #{tracker.duration} seconds
Checks run: #{checks.checks_run.sort.join(", ")}
HEADER
  end
end
