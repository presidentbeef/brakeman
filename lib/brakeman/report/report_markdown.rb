Brakeman.load_brakeman_dependency 'terminal-table'

class Brakeman::Report::Markdown < Brakeman::Report::Base

  class MarkdownTable < Terminal::Table

    def initialize options = {}, &block
      options[:style] ||= {}
      options[:style].merge!({
          :border_x => '-',
          :border_y => '|',
          :border_i => '|'
      })
      super options, &block
    end

    def render
      super.split("\n")[1...-1].join("\n")
    end
    alias :to_s :render

  end

  def generate_report
    out = "# BRAKEMAN REPORT\n\n" <<
    generate_metadata.to_s << "\n\n" <<
    generate_checks.to_s << "\n\n" <<
    "### SUMMARY\n\n" <<
    generate_overview.to_s << "\n\n" <<
    generate_warning_overview.to_s << "\n\n"

    #Return output early if only summarizing
    return out if tracker.options[:summary_only]

    if tracker.options[:report_routes] or tracker.options[:debug]
      out << "### CONTROLLERS"  << "\n\n" <<
      generate_controllers.to_s << "\n\n"
    end

    if tracker.options[:debug]
      out << "### TEMPLATES\n\n" <<
      generate_templates.to_s << "\n\n"
    end

    res = generate_errors
    out << "### Errors\n\n" << res.to_s << "\n\n" if res

    res = generate_warnings
    out << "### SECURITY WARNINGS\n\n" << res.to_s << "\n\n" if res

    res = generate_controller_warnings
    out << "### Controller Warnings:\n\n" << res.to_s << "\n\n" if res

    res = generate_model_warnings
    out << "### Model Warnings:\n\n" << res.to_s << "\n\n" if res

    res = generate_template_warnings
    out << "### View Warnings:\n\n" << res.to_s << "\n\n" if res

    out
  end

  def generate_metadata
    MarkdownTable.new(
      :headings =>
        ['Application path', 'Rails version', 'Brakeman version', 'Started at', 'Duration']
    ) do |t|
      t.add_row([
        tracker.app_path,
        rails_version,
        Brakeman::Version,
        tracker.start_time,
        "#{tracker.duration} seconds",
      ])
    end
  end

  def generate_checks
    MarkdownTable.new(:headings => ['Checks performed']) do |t|
      t.add_row([checks.checks_run.sort.join(", ")])
    end
  end

  def generate_overview
    num_warnings = all_warnings.length

    MarkdownTable.new(:headings => ['Scanned/Reported', 'Total']) do |t|
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
      table = MarkdownTable.new(:headings => ['Output']) do |t|
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

    MarkdownTable.new(:headings => headings) do |t|
      value_array.each { |value_row| t.add_row value_row }
    end
  end

  def convert_warning warning, original
    warning["Confidence"] = TEXT_CONFIDENCE[warning["Confidence"]]
    warning["Message"] = markdown_message original, warning["Message"]
    warning["Warning Type"] = "[#{warning['Warning Type']}](#{original.link})" if original.link
    warning
  end

  # Escape and code format warning message
  def markdown_message warning, message
    if warning.file
      github_url = github_url warning.file, warning.line
      message.gsub!(/(near line \d+)/, "[\\1](#{github_url})") if github_url
    end
    if warning.code
      code = warning.format_code
      message.gsub(code, "`#{code.gsub('`','``').gsub(/\A``|``\z/, '` `')}`")
    else
      message
    end
  end

end
