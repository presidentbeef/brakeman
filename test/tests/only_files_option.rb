abort "Please run using test/test.rb" unless defined? BrakemanTester

Rails32OnlyFiles = BrakemanTester.run_scan "rails3.2", "Rails 3.2", { :only_files => ["app/views/users/"], :skip_files => ["app/views/users/sanitized.html.erb"] }

class OnlyFilesOptionTests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def expected
    @expected ||= {
      :controller => 0,
      :model => 0,
      :template => 1,
      :generic => 4 }


    if RUBY_PLATFORM == 'java'
      @expected[:generic] += 1
    end

    @expected
  end

  def report
    Rails32OnlyFiles
  end

  def test_escaped_params_to_json
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 21,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /show\.html\.erb/
  end

  def test_cross_site_scripting_slim_partial_param
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 6,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /_slimmer\.html\.slim/
  end

  # This is the template that is skipped, should be no warning
  def test_xss_sanitize_css_CVE_2013_1855
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 2,
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ a\ vulnerability\ in\ s/,
      :confidence => 0,
      :file => /sanitized\.html\.erb/
  end

end
