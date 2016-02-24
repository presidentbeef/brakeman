abort "Please run using test/test.rb" unless defined? BrakemanTester

class Rails5Tests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    @@report ||= BrakemanTester.run_scan "rails5", "Rails 5", run_all_checks: true
  end

  def expected
    @@expected ||= {
      :controller => 0,
      :model => 0,
      :template => 2,
      :generic => 5
    }
  end

  def test_mass_assignment_with_safe_attrasgn
    assert_warning :type => :warning,
      :warning_code => 70,
      :fingerprint => "046f3c6cc9a55464d21837b583c672c26532cd46c1f719853a1a15b790baf8ea",
      :warning_type => "Mass Assignment",
      :line => 78,
      :message => /^Parameters\ should\ be\ whitelisted\ for\ mas/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:params), :permit!),
      :user_input => nil
  end

  def test_dangerous_send_with_safe_call
    assert_warning :type => :warning,
      :warning_code => 23,
      :fingerprint => "21c9eef1c001e48a0bfedfa11ff0f9d96b0c106f1016218712dabc088b2e69b6",
      :warning_type => "Dangerous Send",
      :line => 76,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:call, nil, :x), :send, s(:call, s(:params), :[], s(:lit, :x))),
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_no_symbol_denial_of_service
    assert_no_warning :type => :warning,
      :warning_code => 59,
      :fingerprint => "78ba8fe2efc151bc8eca64f36940d1423a8fb92f17a8b7858bffba6cb372490b",
      :warning_type => "Denial of Service",
      :line => 83,
      :message => /^Symbol\ conversion\ from\ unsafe\ string\ \(pa/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:call, s(:params), :[], s(:lit, :x)), :to_sym),
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
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
