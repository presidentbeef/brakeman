abort "Please run using test/test.rb" unless defined? BrakemanTester

class Rails4Tests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    external_checks_path = File.expand_path(File.join(File.dirname(__FILE__), "..", "/apps/rails4/external_checks"))
    @@report ||= BrakemanTester.run_scan "rails4", "Rails 4", {:additional_checks_path => [external_checks_path], :run_all_checks => true, :additional_libs_path => ["app/api"]}
  end

  def expected
    @expected ||= {
      :controller => 0,
      :model => 2,
      :template => 7,
      :generic => 62
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

  def test_redirects_with_explicit_host_do_not_warn
    assert_no_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "b5a1bf2d1634564c82436e569c9ea874e355d4538cdc4dc4a8e6010dc9a7c11e",
      :warning_type => "Redirect",
      :line => 59,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => s(:params, s(:lit, :host), s(:str, "example.com"))

    assert_no_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "d04df9716ee4c8cadcb5f046e73ee06c3f1606e8b522f6e3130ac0a33fbc4d73",
      :warning_type => "Redirect",
      :line => 61,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => s(:params, s(:lit, :host), s(:call, s(:const, :User), :canonical_url))

    assert_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "25846ea0cd5178f2af4423a9fc1d7212983ee7f7ba4ca9f35f890e7ef00d9bf9",
      :warning_type => "Redirect",
      :line => 63,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => s(:params, s(:lit, :host), s(:call, s(:params), :[], s(:lit, :host)))
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
      :fingerprint => "e023f55d7d83631e750435a7d8f432e7e6d0d87b0a82706f91f247ce004830c2",
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

  def test_nested_send
    assert_warning :type => :warning,
      :warning_code => 23,
      :fingerprint => "8034183b1b7e4b3d7ad4d60c59e2de9252f277c8ab5dfb408f628b15f03645c3",
      :warning_type => "Dangerous Send",
      :line => 72,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_sql_injection_connection_execute
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "7e96859dfdd7755eaa51af9ee04731c739af364215a97673b7576f348e88fcf1",
      :warning_type => "SQL Injection",
      :line => 8,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/account.rb",
      :user_input => s(:call, nil, :version)
  end

  def test_sql_injection_select_rows
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "f1a6d026c789b6a029812171695e88fc0de85116d6bba6df61235ccca8194827",
      :warning_type => "SQL Injection",
      :line => 54,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :published))
  end

  def test_sql_injection_select_values
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "700c504a68786c6a8d7a7125b5a722ede615e0f998f3c385d65bd12189220a99",
      :warning_type => "SQL Injection",
      :line => 46,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => s(:call, s(:iter, s(:call, s(:call, nil, :destinations), :map), s(:args, :d), s(:call, s(:lvar, :d), :id)), :join, s(:str, ","))
  end

  def test_sql_injection_exec_query
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "f99145dd8cfb1abca2ff36722b4bd136382d86ffd2bb28eb5ac6d064677c845f",
      :warning_type => "SQL Injection",
      :line => 12,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/account.rb",
      :user_input => s(:call, s(:self), :type)
  end

  def test_sql_injection_exec_update
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "cf9a74253c027dafb7f6bc090b0c4a7c36e9982d15c46e40bda37eeee78966ef",
      :warning_type => "SQL Injection",
      :line => 5,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/account.rb",
      :user_input => s(:call, s(:self), :type)
  end

  def test_sql_injection_in_select_args
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "bd8c539a645aa417d538cbe7b658cc1c9743f61d1e90c948afacc7e023b30a62",
      :warning_type => "SQL Injection",
      :line => 68,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_sql_injection_sanitize
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "bf92408cc7306b3b2f74cac830b9328a1cc2cc8d7697eb904d04f5a2d46bc31c",
      :warning_type => "SQL Injection",
      :line => 3,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :age))

    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "83d8270fd90fb665f2174fe170f51e94945de02879ed617f2f45d4434d5e5593",
      :warning_type => "SQL Injection",
      :line => 3,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/user.rb",
      :user_input => s(:call, nil, :sanitize, s(:lvar, :x))
  end

  def test_sql_injection_chained_call_in_scope
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "aa073ab210f9f4a800b5595241a6274656d37087a4f433d4b596516e1227d91b",
      :warning_type => "SQL Injection",
      :line => 6,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/user.rb",
      :user_input => s(:lvar, :col)
  end

  def test_sql_injection_in_find_by
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "660d7f796162d23ff209f2d35bb647b3d0cc6ad280e9320ce9d3b2853c508730",
      :warning_type => "SQL Injection",
      :line => 47,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :age_limit))
  end

  def test_sql_injection_in_find_by!
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "6f743b0a084c132d3bd074a0d22e197d6c81018028f6166324de1970616c4cbd",
      :warning_type => "SQL Injection",
      :line => 48,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :user_search))
  end

  def test_dynamic_render_path_with_before_action
    assert_warning :type => :warning,
      :warning_code => 15,
      :fingerprint => "5b2267a68b4bfada283b59bdb9f453489111a5f2c335737588f88135d99426fa",
      :warning_type => "Dynamic Render Path",
      :line => 14,
      :message => /^Render\ path\ contains\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :page))
  end

  def test_dynamic_render_path_with_prepend_before_action
    assert_warning :type => :warning,
      :warning_code => 15,
      :fingerprint => "fa1ad77b62059d1aeeb48217a94cc03a0109b1f17d8332c0e3a5718360de9a8c",
      :warning_type => "Dynamic Render Path",
      :line => 19,
      :message => /^Render\ path\ contains\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :page))
  end

  def test_no_cross_site_scripting_in_case_value
    assert_no_warning :type => :template,
      :warning_code => 5,
      :fingerprint => "e9a2843313999c2e856065efaf0a84ffc56ed912112c34927f406339bb395715",
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 2,
      :relative_path => "app/views/users/case_statement.html.erb",
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_cross_site_request_forgery_with_skip_before_action
    assert_warning :type => :warning,
      :warning_code => 8,
      :fingerprint => "320daba73937ffd333f10e5b578520dd90ba681962079bb92a775fb602e2d185",
      :warning_type => "Cross-Site Request Forgery",
      :line => 11,
      :message => /^Use\ whitelist\ \(:only\ =>\ \[\.\.\]\)\ when\ skipp/,
      :confidence => 1,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => nil
  end

  def test_redirect_to_new_query_methods
    assert_no_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "410e22682c2ebd663204362aac560414233b5c225fbc4259d108d2c760bfcbe4",
      :warning_type => "Redirect",
      :line => 38,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:const, :User), :find_by, s(:hash, s(:lit, :name), s(:call, s(:params), :[], s(:lit, :name))))

    assert_no_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "c01e127b45d9010c495c6fd731baaf850f9a5bbad288cf9df66697d23ec6de4a",
      :warning_type => "Redirect",
      :line => 40,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:const, :User), :find_by!, s(:hash, s(:lit, :name), s(:call, s(:params), :[], s(:lit, :name))))

    assert_no_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "9dd39bc751eab84c5485fa35966357b6aacb8830bd6812c7a228a02c5ac598d0",
      :warning_type => "Redirect",
      :line => 42,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:call, s(:const, :User), :where, s(:hash, s(:lit, :stuff), s(:lit, 1))), :take)
  end

  def test_symbol_dos_with_safe_parameters
    assert_no_warning :type => :warning,
      :warning_code => 59,
      :fingerprint => "53a74ac0c23e934a1d439e0b53ce818a22db6b23a696a61cd7dfb5b19175240a",
      :warning_type => "Denial of Service",
      :line => 52,
      :message => /^Symbol\ conversion\ from\ unsafe\ string\ \(pa/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :controller))

    assert_no_warning :type => :warning,
      :warning_code => 59,
      :fingerprint => "d569b240f71e4fc4cc6e91559923baea941a1341d1d70fd6c1c36813947e369d",
      :warning_type => "Denial of Service",
      :line => 53,
      :message => /^Symbol\ conversion\ from\ unsafe\ string\ \(pa/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :action))
  end

  def test_regex_denial_of_service
    assert_warning :type => :warning,
      :warning_code => 76,
      :fingerprint => "f162a94e8ba3c94a8e997b470687e9d5e44a7692b99248b8bc3e689c1a1b86ff",
      :warning_type => "Denial of Service",
      :line => 38,
      :message => /^Parameter\ value\ used\ in\ regex/,
      :confidence => 0,
      :relative_path => "app/controllers/another_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :x))

    assert_no_warning :type => :template,
      :warning_code => 76,
      :fingerprint => "7d3359e28705b6a4392a1dd6ab9c424e7f7c754cdf2df1d932168ab8a77840c2",
      :warning_type => "Denial of Service",
      :line => 1,
      :message => /^Parameter\ value\ used\ in\ regex/,
      :confidence => 0,
      :relative_path => "app/views/another/use_params_in_regex.html.erb",
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_i18n_xss_CVE_2013_4491_workaround
    assert_no_warning :type => :warning,
      :warning_code => 63,
      :fingerprint => "7ef985c538fd302e9450be3a61b2177c26bbfc6ccad7a598006802b0f5f8d6ae",
      :warning_type => "Cross Site Scripting",
      :message => /^Rails\ 4\.0\.0\ has\ an\ XSS\ vulnerability\ in\ /,
      :file => /Gemfile\.lock/,
      :confidence => 1,
      :relative_path => /Gemfile/
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

  def test_number_to_currency_CVE_2014_0081
    assert_warning :type => :template,
      :warning_code => 74,
      :fingerprint => "2d06291f03b443619407093e5921ee1e4eb77b1bf045607d776d9493da4a3f95",
      :warning_type => "Cross Site Scripting",
      :line => 9,
      :message => /^Format\ options\ in\ number_to_currency\ are/,
      :confidence => 0,
      :relative_path => "app/views/users/index.html.erb",
      :user_input => s(:call, s(:call, nil, :params), :[], s(:lit, :currency))

    assert_warning :type => :template,
      :warning_code => 74,
      :fingerprint => "c5f481595217e42fbeaf40f32e6407e66d64d246a9729c2c199053e64365ac96",
      :warning_type => "Cross Site Scripting",
      :line => 12,
      :message => /^Format\ options\ in\ number_to_percentage\ a/,
      :confidence => 0,
      :relative_path => "app/views/users/index.html.erb",
      :user_input => s(:call, s(:call, nil, :params), :[], s(:lit, :format))
  end

  def test_simple_format_xss_CVE_2013_6416
    assert_warning :type => :warning,
      :warning_code => 67,
      :fingerprint => "e950ee1043d7f66b7f6ce99c2bf0876bd3ce8cb12818b52565b905cdb6004bad",
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Rails\ 4\.0\.0 has\ a\ vulnerability\ in/,
      :confidence => 1,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_cross_site_scripting_render_text
    assert_warning :type => :warning,
      :warning_code => 84,
      :fingerprint => "9e40043f992762c78415ef06c2b50916d6f16112759fb2762b9a781e09d651e0",
      :warning_type => "Cross Site Scripting",
      :line => 24,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/controllers/another_controller.rb",
      :user_input => nil

    assert_warning :type => :warning,
      :warning_code => 84,
      :fingerprint => "e8ab2a0727aec11bd56cdac0fa0e9f340e2d739fd964f0d9fe044f0707544bf0",
      :warning_type => "Cross Site Scripting",
      :line => 25,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 1,
      :relative_path => "app/controllers/another_controller.rb",
      :user_input => nil

    assert_warning :type => :warning,
      :warning_code => 84,
      :fingerprint => "44697e7dc6c955c6bd7747c31f3c7617c0da3dcdb9bdae0963b62cbc4462e39f",
      :warning_type => "Cross Site Scripting",
      :line => 26,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/controllers/another_controller.rb",
      :user_input => nil

    assert_warning :type => :warning,
      :warning_code => 84,
      :fingerprint => "e8ab2a0727aec11bd56cdac0fa0e9f340e2d739fd964f0d9fe044f0707544bf0",
      :warning_type => "Cross Site Scripting",
      :line => 27,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 1,
      :relative_path => "app/controllers/another_controller.rb",
      :user_input => nil
  end

  def test_cross_site_scripting_render_inline
    assert_warning :type => :warning,
      :warning_code => 84,
      :fingerprint => "9e40043f992762c78415ef06c2b50916d6f16112759fb2762b9a781e09d651e0",
      :warning_type => "Cross Site Scripting",
      :line => 29,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/controllers/another_controller.rb",
      :user_input => nil

    assert_warning :type => :warning,
      :warning_code => 84,
      :fingerprint => "e8ab2a0727aec11bd56cdac0fa0e9f340e2d739fd964f0d9fe044f0707544bf0",
      :warning_type => "Cross Site Scripting",
      :line => 30,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 1,
      :relative_path => "app/controllers/another_controller.rb",
      :user_input => nil
  end

  def test_cross_site_scripting_with_double_equals
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "046c3a770f455c30aa5e3a49bc1309e6511c142783e2f1d0c0eddcbcef366cef",
      :warning_type => "Cross Site Scripting",
      :line => 16,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/users/index.html.erb",
      :user_input => nil
  end

  def test_cross_site_scripting_with_html_safe
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "b04cfd8d120b773a3e9f70af8762f7efa7c5ca5c7f83136131d6cc75259cd429",
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/another/html_safe_is_not.html.erb",
      :user_input => nil
  end

  def test_xss_haml_line_number
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "f46cf9e2ae9df8f14d195c41589aa3f64a2347b93b899d8871bf4daffeb33c5f",
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/users/haml_test.html.haml",
      :user_input => nil
  end

  def test_cross_site_scripting_warning_code_for_weak_xss
    assert_warning :type => :template,
      :warning_code => 2,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 2,
      :relative_path => "app/views/another/various_xss.html.erb",
      :user_input => s(:call, s(:call, nil, :params), :[], s(:lit, :x))
  end

  def test_cross_site_scripting_no_warning_on_helper_methods_with_targets
    assert_no_warning :type => :template,
      :warning_code => 2,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 2,
      :relative_path => "app/views/another/various_xss.html.erb",
      :user_input => s(:call, s(:call, nil, :params), :[], s(:lit, :t))
  end

  def test_cross_site_scripting_warn_on_url_methods_in_href
    assert_warning :type => :template,
      :warning_code => 4,
      :fingerprint => "92d5f7afb5676d2aca85d6dc796d3606ec225c178a3727ba6a790138276a7c1c",
      :warning_type => "Cross Site Scripting",
      :line => 2,
      :message => /^Unsafe\ parameter\ value\ in\ link_to\ href/,
      :confidence => 1,
      :relative_path => "app/views/another/various_xss.html.erb",
      :user_input => s(:call, nil, :params)
  end

  def test_cross_site_scripting_no_warning_on_path_methods_in_href
    assert_no_warning :type => :template,
      :warning_code => 4,
      :fingerprint => "75956429768c8c53ee3f9932320db67a9d2e0d6fe87431eb290156d0d31d8dba",
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unsafe\ parameter\ value\ in\ link_to\ href/,
      :confidence => 1,
      :relative_path => "app/views/another/various_xss.html.erb",
      :user_input => s(:call, nil, :params)
  end


  def test_sql_injection_in_chained_string_building
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "e60bf02af3884ea73227f05e0b5e00a8ed4466958c22223dbbc4fc4f828c6a1c",
      :warning_type => "SQL Injection",
      :line => 34,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/models/account.rb",
      :user_input => s(:call, s(:call, s(:params), :[], s(:lit, :more_ids)), :join, s(:str, ","))
  end

  def test_no_sql_injection_due_to_skipped_filter
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "47709afc6e3ba4db08a7e6a6b9bda9644c0e8827437eb3489626b2471e0414b5",
      :warning_type => "SQL Injection",
      :line => 14,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/another_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_sql_injection_ignore_to_sym
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "f2e6d5d952c841a148c086beb09ad2961ab9854215f3665babd574aaa4aaaf83",
      :warning_type => "SQL Injection",
      :line => 13,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/models/user.rb",
      :user_input => s(:call, s(:call, s(:const, :User), :table_name), :to_sym)

    # This is a side effect of the test above
    assert_warning :type => :warning,
      :warning_code => 59,
      :fingerprint => "80fce17f43faed45ada3a85acd3902ab32478e585190b25dbb4d5ce483a463f7",
      :warning_type => "Denial of Service",
      :line => 13,
      :message => /^Symbol\ conversion\ from\ unsafe\ string\ \(mo/,
      :confidence => 1,
      :relative_path => "app/models/user.rb",
      :user_input => s(:call, s(:const, :User), :table_name)
  end

  def test_sql_injection_scope_alias_processing
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "a28e3653220903b78e2f00f1e571aa7afaa4f7db6f0789be8cf59c1b9eb583a1",
      :warning_type => "SQL Injection",
      :line => 13,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/email.rb",
      :user_input => s(:lvar, :task_table)
  end

  def test_sql_injection_with_to_s_on_string_interp
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "76279bb48be9716ee4618dbd0a3cda08a63fc1053484c4f29c0214940a57a202",
      :warning_type => "SQL Injection",
      :line => 39,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/account.rb",
      :user_input => s(:lvar, :locale)
  end

  def test_sql_injection_string_concat
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "b92b1e8d755fb15bed56f8e6f872f81784813b0eae3682b68dd0601e4fb9c0a6",
      :warning_type => "SQL Injection",
      :line => 51,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/another_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :search))
  end

  def test_no_sql_injection_from_arel_methods
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "61d957cdeca70a82f53d7ec72287fc21f67c67c6e8dbc9c3c4cb2d115f3a5602",
      :warning_type => "SQL Injection",
      :line => 30,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/models/user.rb"

    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "46a08db9c5b2739027a34c37cbb79c0813247e5bba856705a56174173e230f4b",
      :warning_type => "SQL Injection",
      :line => 32,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/models/user.rb"

    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "64233e939bcef59cf6100c75cfefaf2968734305d4431622556e2f612b10a912",
      :warning_type => "SQL Injection",
      :line => 33,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/models/user.rb"
  end

  def test_format_validation_model_alias_processing
    assert_warning :type => :model,
      :warning_code => 30,
      :fingerprint => "d2bfa987fd0e59d1d515a0bc0baaf378d1dd75483184c945b662b96d370add28",
      :warning_type => "Format Validation",
      :line => 8,
      :message => /^Insufficient\ validation\ for\ 'email'\ usin/,
      :confidence => 0,
      :relative_path => "app/models/email.rb",
      :user_input => nil
  end

  def test_additional_libs_option
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "e1bff55541ac57c8bae7b027e34c23bfe76f675d5a741d767d4a533bbce9ab4a",
      :warning_type => "Command Injection",
      :line => 4,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/api/api.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :dir))
  end

  def test_command_injection_in_library
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "9a11e7271784d69c667ad82481596096781a4873297d3f7523d290f51465f9d6",
      :warning_type => "Command Injection",
      :line => 3,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/sweet_lib.rb",
      :user_input => s(:lvar, :bad)
  end

  def test_command_injection_interpolated_string_in_library
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "83151193b403812e79a00a3bf8f1e8a01d0232b6b8ae5b1bccb2fd146299e8c6",
      :warning_type => "Command Injection",
      :line => 8,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/sweet_lib.rb",
      :user_input => s(:ivar, :@bad)
  end

  def test_command_injection_from_not_skipping_before_filter
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "b4a4bfc1dd6f5f193c9cd3f0819abb936375eee379e5373c08d23957d3af1cd0",
      :warning_type => "Command Injection",
      :line => 18,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/another_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_command_injection_in_open
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "e5316ae15f7db1b2232599d86859229ce01fb6eff1e6d273dbc154345c374d67",
      :warning_type => "Command Injection",
      :line => 81,
      :message => /^Possible\ command\ injection\ in\ open\(\)/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :url))

    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "b35ce0b104d755d40bec760daf5ca33578036f737094e453b9c79e0c441ef2b7",
      :warning_type => "Command Injection",
      :line => 83,
      :message => /^Possible\ command\ injection\ in\ open\(\)/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_file_access_in_open
    assert_warning :type => :warning,
      :warning_code => 16,
      :fingerprint => "e860688d22411c19cb37652e2b41de6475ce094cf92dd6d66ce6b840e8e74c4b",
      :warning_type => "File Access",
      :line => 81,
      :message => /^Parameter\ value\ used\ in\ file\ name/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :url))

    assert_warning :type => :warning,
      :warning_code => 16,
      :fingerprint => "259391ba0e21aa57fc0cadae71741c88b1cd86366e2f46f8347bf8ded1f3b526",
      :warning_type => "File Access",
      :line => 82,
      :message => /^Parameter\ value\ used\ in\ file\ name/,
      :confidence => 2,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :url))

    assert_warning :type => :warning,
      :warning_code => 16,
      :fingerprint => "2e235612f5ee3a6c20a094cec38c65ec4ae5f9550cd2cd31da69d5ef751967e6",
      :warning_type => "File Access",
      :line => 83,
      :message => /^Parameter\ value\ used\ in\ file\ name/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :x))

    assert_warning :type => :warning,
      :warning_code => 16,
      :fingerprint => "a554792e632ec66fa9bee7a880a0ebf5b1938603ee2b673d240d03c4b9574ad9",
      :warning_type => "File Access",
      :line => 84,
      :message => /^Parameter\ value\ used\ in\ file\ name/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_sql_injection_CVE_2013_6417
    assert_warning :type => :warning,
      :warning_code => 69,
      :fingerprint => "e1b66f4311771d714a13be519693c540d7e917511a758827d9b2a0a7f958e40f",
      :warning_type => "SQL Injection",
      :line => 4,
      :file => /Gemfile/,
      :message => /^Rails\ 4\.0\.0 contains\ a\ SQL\ injection\ vul/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_sql_injection_CVE_2014_0080
    assert_warning :type => :warning,
      :warning_code => 72,
      :fingerprint => "0ba20216bdda1cc067f9e4795bdb0d9224fd23c58317ecc09db67b6b38a2d0f0",
      :warning_type => "SQL Injection",
      :line => 6,
      :file => /Gemfile/,
      :message => /^Rails\ 4\.0\.0\ contains\ a\ SQL\ injection\ vul/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_remote_code_execution_CVE_2014_0130
    assert_warning :type => :warning,
      :warning_code => 77,
      :fingerprint => "e833fd152ab95bf7481aada185323d97cd04c3e2322b90f3698632f4c4c04441",
      :warning_type => "Remote Code Execution",
      :line => nil,
      :message => /^Rails\ 4\.0\.0\ with\ globbing\ routes\ is\ vuln/,
      :confidence => 1,
      :relative_path => "config/routes.rb",
      :user_input => nil
  end

  def test_sql_injection_CVE_2014_3482
    assert_warning :type => :warning,
      :warning_code => 78,
      :fingerprint => "5c9706393849d7de5125a3688562aea31e112a7b09d0abbb461ee5dc7c1751b8",
      :warning_type => "SQL Injection",
      :line => 4,
      :file => /Gemfile/,
      :message => /^Rails\ 4\.0\.0\ contains\ a\ SQL\ injection\ vul/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_sql_injection_CVE_2014_3483
    assert_warning :type => :warning,
      :warning_code => 79,
      :fingerprint => "4a60c60c39e12b1dd1d8b490f228594f0a555aa5447587625df362327e86ad2f",
      :warning_type => "SQL Injection",
      :line => 4,
      :file => /Gemfile/,
      :message => /^Rails\ 4\.0\.0\ contains\ a\ SQL\ injection\ vul/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_mass_assignment_CVE_2014_3514
    assert_warning :type => :warning,
      :warning_code => 81,
      :fingerprint => "c4a619b7316e45a5927b098294ff39d7206f84bac084402630318bf6f89f396d",
      :warning_type => "Mass Assignment",
      :line => 57,
      :message => /^create_with\ is\ vulnerable\ to\ strong\ para/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => nil

    assert_warning :type => :warning,
      :warning_code => 81,
      :fingerprint => "c4a619b7316e45a5927b098294ff39d7206f84bac084402630318bf6f89f396d",
      :warning_type => "Mass Assignment",
      :line => 58,
      :message => /^create_with\ is\ vulnerable\ to\ strong\ para/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => nil

    assert_warning :type => :warning,
      :warning_code => 81,
      :fingerprint => "8c55b05e3467934ac900567d47b4ac496e9761424b66b246585d14ba5b2b0240",
      :warning_type => "Mass Assignment",
      :line => 61,
      :message => /^create_with\ is\ vulnerable\ to\ strong\ para/,
      :confidence => 1,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => nil

    assert_warning :type => :warning,
      :warning_code => 81,
      :fingerprint => "aafdaf40064466b1eea16ca053072fb2ef20c999411108d606c8555ade2ce629",
      :warning_type => "Mass Assignment",
      :line => 62,
      :message => /^create_with\ is\ vulnerable\ to\ strong\ para/,
      :confidence => 2,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => nil

  end

  def test_CVE_2015_3227
    assert_warning :type => :warning,
      :warning_code => 88,
      :fingerprint => "6ad4464dbb2a999591c7be8346dc137c3372b280f4a8b0c024fef91dfebeeb83",
      :warning_type => "Denial of Service",
      :line => 4,
      :message => /^Rails\ 4\.0\.0\ is\ vulnerable\ to\ denial\ of\ s/,
      :confidence => 1,
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

  def test_ssl_verification_bypass_net_start
    assert_warning :type => :warning,
      :warning_code => 71,
      :fingerprint => "fed73f1d7511e72e158a7080eefe377c0c34ad18190471829216e9a2c4f7126d",
      :warning_type => "SSL Verification Bypass",
      :line => 12,
      :message => /^SSL\ certificate\ verification\ was\ bypasse/,
      :confidence => 0,
      :relative_path => "lib/sweet_lib.rb",
      :user_input => nil
  end

  def test_unscoped_find_by_id_bang
    assert_warning :type => :warning,
      :warning_code => 82,
      :fingerprint => "4d88d42b82e11010ba1fb67f587bb756068caefe73bb74cc9c3e6f3b9842810f",
      :warning_type => "Unscoped Find",
      :line => 66,
      :message => /^Unscoped\ call\ to\ Email\#find_by_id!/,
      :confidence => 2,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:call, s(:params), :[], s(:lit, :email)), :[], s(:lit, :id))
  end

  def test_before_filter_block
    assert_warning :type => :warning,
      :warning_code => 13,
      :fingerprint => "f8081023e9a6026264eaee41a4a1f520fc98ee5dbcba2129245e6a3873cb6409",
      :warning_type => "Dangerous Eval",
      :line => 7,
      :message => /^User\ input\ in\ eval/,
      :confidence => 0,
      :relative_path => "app/controllers/another_controller.rb",
      :method => :before_filter,
      :user_input => s(:call, s(:call, nil, :params), :[], s(:lit, :x))
  end

  def test_eval_duplicates
    assert_warning :type => :warning,
      :warning_code => 13,
      :fingerprint => "33067304aaa21c6a874fed3b9bb0084cb66b607cc620065cb8ab06a640d3ab14",
      :warning_type => "Dangerous Eval",
      :line => 88,
      :message => /^User\ input\ in\ eval/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :x))

    assert_no_warning :type => :template,
      :warning_code => 13,
      :fingerprint => "dc94bedbdf82991d7a356de94650325c256c5876227480b3b98e24aadaab1fd5",
      :warning_type => "Dangerous Eval",
      :line => 1,
      :message => /^User\ input\ in\ eval/,
      :confidence => 0,
      :relative_path => "app/views/users/eval_it.html.erb",
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_cross_site_request_forgery_setting_in_api_controller
    assert_no_warning :type => :controller,
      :warning_code => 7,
      :fingerprint => "6f5239fb87c64764d0c209014deb5cf504c2c10ee424bd33590f0a4f22e01d8f",
      :warning_type => "Cross-Site Request Forgery",
      :line => nil,
      :message => /^'protect_from_forgery'\ should\ be\ called\ /,
      :confidence => 0,
      :relative_path => "app/controllers/application_controller.rb",
      :user_input => nil
  end

  #Verify checks external to Brakeman are loaded
  def test_external_checks
    assert defined? Brakeman::CheckExternalCheckTest
    #Initial "Check" removed from check names
    assert report[:checks_run].include? "ExternalCheckTest"
  end
end
