abort "Please run using test/test.rb" unless defined? BrakemanTester

EXTERNAL_CHECKS_PATH = File.expand_path(File.join(File.dirname(__FILE__), "..", "/apps/rails4/external_checks"))
Rails4 = BrakemanTester.run_scan "rails4", "Rails 4", {:additional_checks_path => [EXTERNAL_CHECKS_PATH], :run_all_checks => true}

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
      :template => 2,
      :generic => 39
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
      :line => 55,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => s(:params, s(:lit, :host), s(:str, "example.com"))

    assert_no_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "d04df9716ee4c8cadcb5f046e73ee06c3f1606e8b522f6e3130ac0a33fbc4d73",
      :warning_type => "Redirect",
      :line => 57,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => s(:params, s(:lit, :host), s(:call, s(:const, :User), :canonical_url))

    assert_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "25846ea0cd5178f2af4423a9fc1d7212983ee7f7ba4ca9f35f890e7ef00d9bf9",
      :warning_type => "Redirect",
      :line => 59,
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

  def test_nested_send
    assert_warning :type => :warning,
      :warning_code => 23,
      :fingerprint => "8034183b1b7e4b3d7ad4d60c59e2de9252f277c8ab5dfb408f628b15f03645c3",
      :warning_type => "Dangerous Send",
      :line => 68,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_sql_injection_connection_execute
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "4efbd2d2fc76d30296c8aa66368ddaf337b4c677778f36cddfa2290da2ec514b",
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
      :fingerprint => "2e3c08dfb1e17f7d2e6ee5d142223477b85d27e6aa88d2d06cf0a00d04ed2d5c",
      :warning_type => "SQL Injection",
      :line => 50,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :published))
  end

  def test_sql_injection_select_values
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "3538776239f624a1101afe68b2e894424e8ae3f68222a6eec9fb4421d01cc557",
      :warning_type => "SQL Injection",
      :line => 46,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/friendly_controller.rb",
      :user_input => s(:call, s(:call_with_block, s(:call, s(:call, nil, :destinations), :map), s(:args, :d), s(:call, s(:lvar, :d), :id)), :join, s(:str, ","))
  end

  def test_sql_injection_exec_query
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "59be915e75d6eb88def8fccebae1f9930bb6e50b2e598c7f04bf98c7a3235219",
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
      :fingerprint => "29fac7fc616f19edf59cc230f7a86292d6c69234b5879868eaf1d954f033974f",
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
      :line => 64,
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
      :fingerprint => "ca9d658a7215099a35b3b3ec3867ffb8fb7ad497d31307ba8952d7dcb85e8ac9",
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

  def test_sql_injection_in_chained_string_building
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "6109b24aecaa204463bcebeb594becfe06d5f3c40cfe092b54a4c5146273e134",
      :warning_type => "SQL Injection",
      :line => 34,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/models/account.rb",
      :user_input => s(:call, s(:call, s(:params), :[], s(:lit, :more_ids)), :join, s(:str, ","))
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

  #Verify checks external to Brakeman are loaded
  def test_external_checks
    assert defined? Brakeman::CheckExternalCheckTest
    #Initial "Check" removed from check names
    assert report[:checks_run].include? "ExternalCheckTest"
  end
end
