require 'json'
require_relative '../test'

class TestReportGeneration < Minitest::Test
  def setup
    @@tracker ||= Brakeman.run(:app_path => "#{TEST_PATH}/apps/rails4", :quiet => true, :report_routes => true, :output_color => false)
    @@report ||= @@tracker.report
  end

  def test_html_sanity
    report = @@report.to_html

    assert report.is_a? String
    assert report.match(/\A<!DOCTYPE HTML SYSTEM>.*<\/html>\z/m)
    report.scan(/<a[^>]+>/).each do |a|
      assert a.include?("noreferrer"), "#{a} does not include 'noreferrer'"
    end
  end

  def test_table_sanity
    require 'highline/io_console_compatible' # For StringIO compatibility
    @@report.to_table
  end

  def test_json_sanity
    report = @@report.to_json
    expected_keys = ["scan_info", "warnings", "errors"]

    assert report.is_a? String

    report_hash = JSON.parse report

    assert (expected_keys - report_hash.keys).empty?, "Expected #{expected_keys - report_hash.keys} to be empty"
  end

  def test_codeclimate_sanity
    report = @@report.to_codeclimate

    assert report.is_a? String
    refute report.include? Dir.pwd # Ensure output does not include absolute paths
  end

  def test_csv_sanity
    headers = ["Confidence", "Warning Type", "CWE", "File", "Line", "Message", "Code", "User Input", "Check Name", "Warning Code", "Fingerprint", "Link"]
    report = @@report.to_csv
    parsed = CSV.parse report, headers: true
    row = parsed.first

    assert_equal row.headers, headers
    assert_equal parsed.length, @@report.tracker.filtered_warnings.length
  end

  def test_csv_report_no_warnings
    assert_nothing_raised do
      Brakeman.run(:app_path => "#{TEST_PATH}/apps/rails4_non_standard_structure", :quiet => true, :report_routes => true).report.to_csv
    end
  end

  def test_obsolete_reporting
    report = @@report.to_s

    assert report.include? "Obsolete Ignore Entries"
    assert report.include? "abcdef01234567890ba28050e7faf1d54f218dfa9435c3f65f47cb378c18cf98"
  end

  def test_tabs_sanity
    report = @@report.to_tabs

    assert report.is_a? String
  end

  def test_text_sanity
    report = @@report.to_s

    assert report.is_a? String
  end

  def test_text_debug_sanity
    @@tracker.options[:debug] = true
    report = @@report.to_s

    assert report.is_a? String
  ensure
    @@tracker.options[:debug] = false
  end

  def test_text_format_all
    require 'brakeman/options'

    options, _ = Brakeman::Options.parse(["--text-fields", "all"])
    tracker = Brakeman.run(:app_path => "#{TEST_PATH}/apps/rails5", :quiet => true, :report_routes => true, :text_fields => options[:text_fields], :output_color => false)
    report = tracker.report.to_s

    assert_includes report, "Confidence:"
    assert_includes report, "Category:"
    assert_includes report, "Category ID:"
    assert_includes report, "Check:"
    assert_includes report, "Code:"
    assert_includes report, "CWE:"
    assert_includes report, "File:"
    assert_includes report, "Fingerprint:"
    assert_includes report, "Line:"
    assert_includes report, "Link:"
    assert_includes report, "Message:"
    assert_includes report, "Render Path:"
  end

  def test_text_format
    @@tracker.options[:text_fields] =
      [:confidence, :category, :category_id, :code, :fingerprint, :line]

    report = @@report.to_s

    assert_includes report, "Confidence:"
    assert_includes report, "Category:"
    assert_includes report, "Category ID:"
    assert_includes report, "Code:"
    assert_includes report, "Fingerprint:"
    assert_includes report, "Line:"
    refute_includes report, "Check:"
    refute_includes report, "File:"
    refute_includes report, "Link:"
    refute_includes report, "Message:"
    refute_includes report, "Render Path:"
  ensure
    @@tracker.options.delete(:text_fields)
  end

  def test_markdown_sanity
    report = @@report.to_markdown

    assert report.is_a? String
    assert report.include? "High"
    assert report.include? "Medium"
    assert report.include? "Weak"
  end

  def test_markdown_debug_sanity
    @@tracker.options[:debug] = true
    report = @@report.to_markdown

    assert report.is_a?(String), "Report wasn't a String, it was a #{report.class}"
  ensure
    @@tracker.options[:debug] = false
  end

  def test_github_sanity
    report = @@report.to_github

    assert report.is_a? String
    assert report.include? "::warning"
  end

  def test_bad_format_type
    assert_raises RuntimeError do
      @@report.format(:to_something_else)
    end
  end

  def test_controller_output
    text_report = @@report.to_s

    assert text_report.include? "Controller Overview"

    html_report = @@report.to_html

    assert html_report.include? "<h2>Controllers</h2>"
  end

  def test_plain_debug_sanity
    @@tracker.options[:debug] = true
    report = @@report.to_plain

    assert report.is_a? String
    assert report.match(/Overview.*Warning Types.*Controller Overview.*Template Output.*Warnings/m)
  ensure
    @@tracker.options[:debug] = false
  end

  def test_github_markdown_sanity
    @@tracker.options[:github_url] = "https://github.com/presidentbeef/brakeman/blob/master/"

    report = @@report.to_markdown

    assert report.is_a? String
    assert report.include? @@tracker.options[:github_url]
  ensure
    @@tracker.options[:github_url] = nil
  end

  def test_junit_sanity
    report = @@report.to_junit

    assert report.is_a? String
    assert report.match(/\A.*<\/testsuites>\z/m)
  end
end
