require 'brakeman/report/report_base'

#Generates a report based on the Tracker and the results of
#Tracker#run_checks. Be sure to +run_checks+ before generating
#a report.
class Brakeman::Report
  attr_reader :tracker

  VALID_FORMATS = [:to_html, :to_pdf, :to_csv, :to_json, :to_tabs, :to_hash, :to_s, :to_markdown]

  def initialize app_tree, tracker
    @app_tree = app_tree
    @tracker = tracker
  end

  def format format
    reporter = case format
    when :to_csv
      require_report 'csv'
      Brakeman::Report::CSV
    when :to_html
      require_report 'html'
      Brakeman::Report::HTML
    when :to_json
      return self.to_json
    when :to_tabs
      require_report 'tabs'
      Brakeman::Report::Tabs
    when :to_hash
      require_report 'hash'
      Brakeman::Report::Hash
    when :to_markdown
      return self.to_markdown
    when :to_s
      return self.to_s
    when :to_pdf
      raise "PDF output is not yet supported."
    else
      raise "Invalid format: #{format}. Should be one of #{VALID_FORMATS.inspect}"
    end

    generate(reporter)
  end

  def method_missing method, *args
    if VALID_FORMATS.include? method
      format method
    else
      super
    end
  end

  def require_report type
    require "brakeman/report/report_#{type}"
  end

  def to_json
    require_report 'json'
    generate Brakeman::Report::JSON
  end

  def to_s
    require_report 'table'
    generate Brakeman::Report::Table
  end

  def to_markdown
    require_report 'markdown'
    generate Brakeman::Report::Markdown
  end

  def generate reporter
    reporter.new(@app_tree, @tracker).generate_report
  end
end
