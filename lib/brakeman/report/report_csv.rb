require 'csv'
require "brakeman/report/report_table"

class Brakeman::Report::CSV < Brakeman::Report::Table
  def generate_report
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

  #Generate header for CSV output
  def csv_header
    header = CSV.generate_line(["Application Path", "Report Generation Time", "Checks Performed", "Rails Version"])
    header << CSV.generate_line([File.expand_path(tracker.app_path), Time.now.to_s, checks.checks_run.sort.join(", "), rails_version])
    "BRAKEMAN REPORT\n\n" + header
  end

  # rely on Terminal::Table to build the structure, extract the data out in CSV format
  def table_to_csv table
    return "" unless table

    Brakeman.load_brakeman_dependency 'terminal-table'
    headings = table.headings
    if headings.is_a? Array
      headings = headings.first
    end

    output = CSV.generate_line(headings.cells.map{|cell| cell.to_s.strip})
    table.rows.each do |row|
      output << CSV.generate_line(row.cells.map{|cell| cell.to_s.strip})
    end
    output
  end
end
