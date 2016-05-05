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
      :generic => 6
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

  def test_mass_assignment_with_slice
    assert_no_warning :type => :warning,
      :warning_code => 70,
      :fingerprint => "79c472e032f2ff16f4688ea9d87ccc1c6def392c9b3e189ee1c4d1c079dd4fbf",
      :warning_type => "Mass Assignment",
      :line => 87,
      :message => /^Parameters\ should\ be\ whitelisted\ for\ mas/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:call, s(:params), :slice, s(:lit, :id)), :permit!),
      :user_input => nil
  end

  def test_sql_injection_with_slice
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "d9f4fec5f738785ea1aed229d192a2d5d2eb0d8805f6ca58fd02416105e0f9db",
      :warning_type => "SQL Injection",
      :line => 88,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:const, :User), :find_by, s(:call, s(:params), :slice, s(:lit, :id))),
      :user_input => s(:call, s(:params), :slice, s(:lit, :id))
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

  def test_secrets_in_source
    assert_warning :type => :warning,
      :warning_code => 101,
      :fingerprint => "eefde7320af81299c41d50840750b5cb509a1fe454ba9179076955bf53b6d966",
      :warning_type => "Authentication",
      :line => 1,
      :message => /^Hardcoded\ value\ for\ DB_PASSWORD\ in\ sourc/,
      :confidence => 1,
      :user_input => nil,
      :relative_path => "config/initializers/secrets.rb"
  end

  def test_skipping_rails_env_test
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "46cda22e00dca87a8715682bd7d8d52cc4a8e705257b27c5e36595ebd1f654f8",
      :warning_type => "SQL Injection",
      :line => 4,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/models/user.rb",
      :code => s(:call, s(:const, :User), :where, s(:params)),
      :user_input => s(:params)
  end

  def test_default_routes_in_test
    assert_no_warning :type => :warning,
      :warning_code => 11,
      :fingerprint => "ff2b76e22c9fd2bc3930f9a935124b9ed9f6ea710bbb5bc7c51505d70ca0f2d5",
      :warning_type => "Default Routes",
      :line => 8,
      :message => /^All\ public\ methods\ in\ controllers\ are\ av/,
      :confidence => 0,
      :relative_path => "config/routes.rb",
      :user_input => nil
  end

  def test_redirect_with_slice
    assert_no_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "b70fe6fa14df927bdfe80e0731c4c4170db0c3c80edad5a4462c7037acde93a4",
      :warning_type => "Redirect",
      :line => 89,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, nil, :redirect_to, s(:call, s(:params), :slice, s(:lit, :back_to))),
      :user_input => s(:call, s(:params), :slice, s(:lit, :back_to))
  end

  def test_cross_site_scripting_with_slice
    assert_no_warning :type => :template,
      :warning_code => 4,
      :fingerprint => "0e7c3fed684f3152150e01986fbdde92741b2d69628156f3f28f30987456c018",
      :warning_type => "Cross Site Scripting",
      :line => 25,
      :message => /^Unsafe\ parameter\ value\ in\ link_to\ href/,
      :confidence => 0,
      :relative_path => "app/views/users/index.html.erb",
      :code => s(:call, nil, :link_to, s(:str, "slice"), s(:call, s(:params), :slice, s(:lit, :url))),
      :user_input => s(:call, s(:params), :slice, s(:lit, :url))
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
