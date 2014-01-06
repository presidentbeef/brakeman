abort "Please run using test/test.rb" unless defined? BrakemanTester

Rails4 = BrakemanTester.run_scan "rails4", "Rails 4"

class Rails4Tests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected
  
  def report
    Rails4
  end

  def expected
    @expected ||= {
      :controller => 0,
      :model => 1,
      :template => 1,
      :generic => 13
    }
  end

  def test_redirects_to_created_model_do_not_warn
    assert_no_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "fedba22f0fbcd96dcaa0b2628ccedba2c0880870992d05b817697efbb36e134f",
      :warning_type => "Redirect",
      :line => 14,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/application_controller.rb",
      :user_input => s(:call, s(:const, :User), :create)

    assert_no_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "1d2d4b0a59ed26a6d591094714dbee81a60a3e686429a44fe2d80f87b94bc555",
      :warning_type => "Redirect",
      :line => 18,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/application_controller.rb",
      :user_input => s(:call, s(:const, :User), :create!)
  end

  def test_session_secret_token
    assert_warning :type => :generic,
      :warning_type => "Session Setting",
      :fingerprint => "715ad9c0d76f57a6a657192574d528b620176a80fec969e2f63c88eacab0b984",
      :line => 12,
      :message => /^Session\ secret\ should\ not\ be\ included\ in/,
      :confidence => 0,
      :file => /secret_token\.rb/,
      :relative_path => "config/initializers/secret_token.rb"
  end

  def test_json_escaped_by_default_in_rails_4
    assert_no_warning :type => :template,
      :warning_code => 5,
      :fingerprint => "3eedfa40819ce95d1d999ad19464023688a0e8bb881fc3e7683b6c3fffb7e51f",
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ model\ attribute\ in\ JSON\ hash/,
      :confidence => 0,
      :relative_path => "app/views/users/index.html.erb"

    assert_no_warning :type => :template,
      :warning_code => 5,
      :fingerprint => "fb0cb7e94e9a4bebd81ef44b336e02f68bf24f2c40e28d4bb5c21641276ea6cf",
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 2,
      :relative_path => "app/views/users/index.html.erb"

    assert_no_warning :type => :template,
      :warning_code => 5,
      :fingerprint => "8ce0a9eacf25be1f862b9074e6ba477d2f0e2ac86955b8510052984570b92d14",
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped\ parameter\ value\ in\ JSON\ hash/,
      :confidence => 0,
      :relative_path => "app/views/users/index.html.erb"

    assert_no_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "b107fcc7742084a766a31332ba5c126f1c1a1cc062884f879dc3204c5f7620c5",
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/users/index.html.erb"
  end

  def test_information_disclosure_local_request_config
    assert_warning :type => :warning,
      :warning_code => 61,
      :fingerprint => "081f5d87a244b41d3cf1d5994cb792d2cec639cd70e4e306ffe1eb8abf0f32f7",
      :warning_type => "Information Disclosure",
      :message => /^Detailed\ exceptions\ are\ enabled\ in\ produ/,
      :confidence => 0,
      :relative_path => "config/environments/production.rb"
  end

  def test_information_disclosure_detailed_exceptions_override
    assert_warning :type => :warning,
      :warning_code => 62,
      :fingerprint => "c1c1c512feca03b77e560939098efabbc2ec9279ef66f75bc63a84f815b54ec2",
      :warning_type => "Information Disclosure",
      :line => 6,
      :message => /^Detailed\ exceptions\ may\ be\ enabled\ in\ 's/,
      :confidence => 0,
      :relative_path => "app/controllers/application_controller.rb"
  end

  def test_redirect_with_instance_variable_from_block
    assert_no_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "e024f0cf67432409ec4afc80216fb2f6c9929fbbd32c2421e8867cd254f22d04",
      :warning_type => "Redirect",
      :line => 12,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/friendly_controller.rb"
  end

  def test_try_and_send_collapsing_with_sqli
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "c96c2984c1ce4f9a0f1205c9e7ac4707253a0553ecb6c7e9d6d4b88c92db7098",
      :warning_type => "SQL Injection",
      :line => 17,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :table))

    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "004e5d6afb7ce520f1a67b65ace238f763ca2feb6a7f552f7dcc86ed3f67a189",
      :warning_type => "SQL Injection",
      :line => 16,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :query))
  end

  def test_i18n_xss_CVE_2013_4491_workaround
    assert_no_warning :type => :warning,
      :warning_code => 63,
      :fingerprint => "de0e11056b9f9af7b8570d5354185cd7e17a18cc61d627555fe4adfff00fb447",
      :warning_type => "Cross Site Scripting",
      :message => /^Rails\ 4\.0\.0\ has\ an\ XSS\ vulnerability\ in\ /,
      :confidence => 1,
      :relative_path => "Gemfile"
  end

  def test_denial_of_service_CVE_2013_6414
    assert_warning :type => :warning,
      :warning_code => 64,
      :fingerprint => "a7b00f08e4a18c09388ad017876e3f57d18040ead2816a2091f3301b6f0e5a00",
      :warning_type => "Denial of Service",
      :message => /^Rails\ 4\.0\.0\ has\ a\ denial\ of\ service\ vuln/,
      :confidence => 1,
      :relative_path => "Gemfile"
  end

  def test_number_to_currency_CVE_2013_6415
    assert_warning :type => :template,
      :warning_code => 66,
      :fingerprint => "0fb96b5f4b3a4dcdc677d126f492441e2f7b46880563a977b1246b30d3c117a0",
      :warning_type => "Cross Site Scripting",
      :line => 9,
      :message => /^Currency\ value\ in\ number_to_currency\ is\ /,
      :confidence => 0,
      :relative_path => "app/views/users/index.html.erb",
      :user_input => s(:call, s(:call, nil, :params), :[], s(:lit, :currency))
  end

  def test_simple_format_xss_CVE_2013_6416
    assert_warning :type => :warning,
      :warning_code => 67,
      :fingerprint => "e950ee1043d7f66b7f6ce99c2bf0876bd3ce8cb12818b52565b905cdb6004bad",
      :warning_type => "Cross Site Scripting",
      :line => nil,
      :message => /^Rails\ 4\.0\.0 has\ a\ vulnerability\ in/,
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
      :message => /^Rails\ 4\.0\.0 contains\ a\ SQL\ injection\ vul/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_mass_assignment_with_permit!
    assert_warning :type => :warning,
      :warning_code => 70,
      :fingerprint => "c2fdd36441441ef7d2aed764731c36fb9f16939ed4df582705f27d46c02fcbe3",
      :warning_type => "Mass Assignment",
      :line => 22,
      :message => /^Parameters\ should\ be\ whitelisted\ for\ mas/,
      :confidence => 0,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => nil

    assert_warning :type => :warning,
      :warning_code => 70,
      :fingerprint => "2f2df4aef71799a6a441783b50e7a43a9bed7da6c8d50e07e73d9d165065ceec",
      :warning_type => "Mass Assignment",
      :line => 28,
      :message => /^Parameters\ should\ be\ whitelisted\ for\ mas/,
      :confidence => 1,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => nil

    assert_warning :type => :warning,
      :warning_code => 70,
      :fingerprint => "4f6a0d82f6ddf5528f3d50545ce353f2f1658d5102a745107ea572af5c2eee4b",
      :warning_type => "Mass Assignment",
      :line => 34,
      :message => /^Parameters\ should\ be\ whitelisted\ for\ mas/,
      :confidence => 1,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => nil

    assert_warning :type => :warning,
      :warning_code => 70,
      :fingerprint => "947bddec4cdd3ff8b2485eec1bd0078352c182a3bca18a5f68da0a64e87d4e80",
      :warning_type => "Mass Assignment",
      :line => 40,
      :message => /^Parameters\ should\ be\ whitelisted\ for\ mas/,
      :confidence => 1,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => nil
  end

  def test_only_desired_attribute_is_ignored
    assert_warning :type => :model,
      :warning_code => 60,
      :fingerprint => "e543ea9186ed27e78ccfeee4e60ceee0c83163ffe0bf50e1ebf3d7b19793c5f4",
      :warning_type => "Mass Assignment",
      :line => nil,
      :message => "Potentially dangerous attribute available for mass assignment: :account_id",
      :confidence => 0,
      :relative_path => "app/models/account.rb",
      :user_input => nil

    assert_no_warning :type => :model,
      :warning_code => 60,
      :message => "Potentially dangerous attribute available for mass assignment: :admin",
      :relative_path => "app/models/account.rb"
  end

  def test_ssl_verification_bypass
    assert_warning :type => :warning,
      :warning_code => 71,
      :warning_type => "SSL Verification Bypass",
      :line => 24,
      :message => /^SSL\ certificate\ verification\ was\ bypassed/,
      :confidence => 0,
      :relative_path => "app/controllers/application_controller.rb",
      :user_input => nil
  end
end
