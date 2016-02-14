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
end
