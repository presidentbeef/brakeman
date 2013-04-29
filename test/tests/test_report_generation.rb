class TestReportGeneration < Test::Unit::TestCase
  Tracker = Brakeman.run("#{TEST_PATH}/apps/rails3.2")

  def test_html_sanity
    report = Tracker.report(:to_html)

    assert report.is_a? String
    assert report.match(/\A<!DOCTYPE HTML SYSTEM>.*<\/html>\z/m)
    report.scan(/<a[^>]+>/).each do |a|
      assert a.include?("no-referrer"), "#{a} does not include 'no-referrer'"
    end
  end

  def test_json_sanity
    report = Tracker.report(:to_json)
    expected_keys = ["scan_info", "warnings", "errors"]

    assert report.is_a? String

    report_hash = MultiJson.load report

    assert (expected_keys - report_hash.keys).empty?, "Expected #{expected_keys - report_hash.keys} to be empty"
  end

  def test_csv_sanity
    report = Tracker.report(:to_csv)

    assert report.is_a? String
  end

  def test_tabs_sanity
    report = Tracker.report(:to_tabs)

    assert report.is_a? String
  end

  def test_text_sanity
    unless RUBY_PLATFORM == "java"
      report = Tracker.report(:to_s)

      assert report.is_a? String
    end
  end
end
