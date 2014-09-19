abort "Please run using test/test.rb" unless defined? BrakemanTester

Rails32OnlyFiles = BrakemanTester.run_scan "rails3.2", "Rails 3.2", { :only_files => ["app/views/users/"], :skip_files => ["app/views/users/sanitized.html.erb"] }

class OnlyFilesOptionTests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def expected
    @expected ||= {
      :controller => 8,
      :model => 0,
      :template => 1,
      :generic => 9 }

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

  def test_i18n_xss_CVE_2013_4491
    assert_warning :type => :warning,
      :warning_code => 63,
      :fingerprint => "de0e11056b9f9af7b8570d5354185cd7e17a18cc61d627555fe4adfff00fb447",
      :warning_type => "Cross Site Scripting",
      :message => /^Rails\ 3\.2\.9\.rc2\ \(.*?\) has\ an\ XSS\ vulnerability/,
      :confidence => 1,
      :relative_path => "Gemfile"
  end

  def test_denial_of_service_CVE_2013_6414
    assert_warning :type => :warning,
      :warning_code => 64,
      :fingerprint => "a7b00f08e4a18c09388ad017876e3f57d18040ead2816a2091f3301b6f0e5a00",
      :warning_type => "Denial of Service",
      :line => nil,
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ a\ denial\ of\ service\ /,
      :confidence => 1,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_number_to_currency_CVE_2014_0081
    assert_warning :type => :warning,
      :warning_code => 73,
      :fingerprint => "f6981b9c24727ef45040450a1f4b158ae3bc31b4b0343efe853fe12c64881695",
      :warning_type => "Cross Site Scripting",
      :line => nil,
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ a\ vulnerability\ in\ n/,
      :confidence => 1,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_sql_injection_CVE_2013_6417
    assert_warning :type => :warning,
      :warning_code => 69,
      :fingerprint => "e1b66f4311771d714a13be519693c540d7e917511a758827d9b2a0a7f958e40f",
      :warning_type => "SQL Injection",
      :line => nil,
      :message => /^Rails\ 3\.2\.9\.rc2 \(.*?\) contains\ a\ SQL\ injection\ vul/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_remote_code_execution_CVE_2014_0130
    assert_warning :type => :warning,
      :warning_code => 77,
      :fingerprint => "93393e44a0232d348e4db62276b18321b4cbc9051b702d43ba2fd3287175283c",
      :warning_type => "Remote Code Execution",
      :line => nil,
      :message => /^Rails\ 3\.2\.9\.rc2\ with\ globbing\ routes\ is\ /,
      :confidence => 0,
      :relative_path => "config/routes.rb",
      :user_input => nil
  end
end
