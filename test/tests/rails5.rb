abort "Please run using test/test.rb" unless defined? BrakemanTester

class Rails5Tests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    @@report ||= BrakemanTester.run_scan "rails5", "Rails 5"
  end

  def expected
    @@expected ||= {
      :controller => 0,
      :model => 0,
      :template => 2,
      :generic => 3
    }
  end

  def test_cross_site_scripting_CVE_2015_7578
    assert_warning :type => :warning,
      :warning_code => 96,
      :fingerprint => "7feea01d5ef6edbc300e34ecffd304a4d76cf306dbc71712a8340a3ac08b6dad",
      :warning_type => "Cross Site Scripting",
      :line => 115,
      :message => /^rails\-html\-sanitizer\ 1\.0\.2\ is\ vulnerable/,
      :confidence => 0,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_cross_site_scripting_CVE_2015_7580
    assert_warning :type => :warning,
      :warning_code => 97,
      :fingerprint => "f542035c0310ab2e76ec6dbccace0954f0d7c576d56d8cfcb03d9836f50bc7c9",
      :warning_type => "Cross Site Scripting",
      :line => 115,
      :message => /^rails\-html\-sanitizer\ 1\.0\.2\ is\ vulnerable/,
      :confidence => 0,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_cross_site_scripting_CVE_2015_7579
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "0d980d69bd0158cfa6a92c12bc49294fe32e9862a758e11fe3cf9e03b6c50489",
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/users/sanitizing.html.erb",
      :code => s(:call, nil, :strip_tags, s(:call, s(:call, nil, :params), :[], s(:lit, :x))),
      :user_input => s(:call, s(:call, nil, :params), :[], s(:lit, :x))
  end

  def test_cross_site_scripting_sanitize_cve
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "e203c837d65aad6ab63e09c2487beabf478534f77f0c20e946a28a38826ca657",
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/users/sanitizing.html.erb",
      :code => s(:call, nil, :sanitize, s(:call, s(:call, nil, :params), :[], s(:lit, :x))),
      :user_input => s(:call, s(:call, nil, :params), :[], s(:lit, :x))
  end

  def test_cross_site_scripting_strip_tags_cve
    assert_warning :type => :warning,
      :warning_code => 98,
      :fingerprint => "9f292c507e0f07fd0ffc7a3d000af464c522ae6a929015256f505f35fb75ac82",
      :warning_type => "Cross Site Scripting",
      :line => 115,
      :message => /^rails\-html\-sanitizer\ 1\.0\.2\ is\ vulnerable/,
      :confidence => 0,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end
end
