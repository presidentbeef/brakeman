class TestReportGeneration < Test::Unit::TestCase
  Report = Brakeman.run(:app_path => "#{TEST_PATH}/apps/rails3.2", :quiet => true, :report_routes => true).report

  def test_html_sanity
    report = Report.to_html

    assert report.is_a? String
    assert report.match(/\A<!DOCTYPE HTML SYSTEM>.*<\/html>\z/m)
    report.scan(/<a[^>]+>/).each do |a|
      assert a.include?("no-referrer"), "#{a} does not include 'no-referrer'"
    end
  end

  def test_json_sanity
    report = Report.to_json
    expected_keys = ["scan_info", "warnings", "errors"]

    assert report.is_a? String

    report_hash = MultiJson.load report

    assert (expected_keys - report_hash.keys).empty?, "Expected #{expected_keys - report_hash.keys} to be empty"
  end

  def test_csv_sanity
    report = Report.to_csv
    parsed = CSV.parse report
    summary_header = ["Application Path", "Report Generation Time", "Checks Performed", "Rails Version"]

    assert report.is_a? String
    assert_equal ["BRAKEMAN REPORT"], parsed[0]
    assert_equal summary_header, parsed[2]
  end

  def test_tabs_sanity
    report = Report.to_tabs

    assert report.is_a? String
  end

  def test_text_sanity
    report = Report.to_s

    assert report.is_a? String
  end

  def test_markdown_sanity
    report = Report.to_markdown

    assert report.is_a? String
  end

  def test_bad_format_type
    assert_raises RuntimeError do
      Report.format(:to_something_else)
    end
  end

  def test_controller_output
    text_report = Report.to_s

    assert text_report.include? "+CONTROLLERS+"

    html_report = Report.to_html

    assert html_report.include? "<h2>Controllers</h2>"
  end
end
