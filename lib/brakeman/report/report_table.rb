Brakeman.load_brakeman_dependency 'terminal-table'

class Brakeman::Report::Table < Brakeman::Report::Base
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

  def generate_overview
    num_warnings = all_warnings.length

    Terminal::Table.new(:headings => ['Scanned/Reported', 'Total']) do |t|
      t.add_row ['Controllers', tracker.controllers.length]
      t.add_row ['Models', tracker.models.length - 1]
      t.add_row ['Templates', number_of_templates(@tracker)]
      t.add_row ['Errors', tracker.errors.length]
      t.add_row ['Security Warnings', "#{num_warnings} (#{warnings_summary[:high_confidence]})"]
      t.add_row ['Ignored Warnings', ignored_warnings.length] unless ignored_warnings.empty?
    end
  end

  #Generate listings of templates and their output
  def generate_templates
    out_processor = Brakeman::OutputProcessor.new
    template_rows = {}
    tracker.templates.each do |name, template|
      unless template[:outputs].empty?
        template[:outputs].each do |out|
          out = out_processor.format out
          template_rows[name] ||= []
          template_rows[name] << out.gsub("\n", ";").gsub(/\s+/, " ")
        end
      end
    end

    template_rows = template_rows.sort_by{|name, value| name.to_s}

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

  def render_array template, headings, value_array, locals
    return if value_array.empty?

    Terminal::Table.new(:headings => headings) do |t|
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
