# NOTE: Please do not add any further tests to the Rails 3.2 application unless
# the issue being tested specifically applies to Rails 3.2 and not the other
# versions.
# If possible, please use the rails5 app. 

require_relative '../test'

class Rails32Tests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def expected
    @expected ||= {
      :controller => 8,
      :model => 5,
      :template => 11,
      :generic => 23 }

    if RUBY_PLATFORM == 'java'
      @expected[:generic] += 1
    end

    @expected
  end

  def report
    @@report ||= BrakemanTester.run_scan "rails3.2", "Rails 3.2"
  end

  def test_rc_version_number
    assert_equal "3.2.9.rc2", report[:config].rails_version
  end

  def test_sql_injection_CVE_2012_5664
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-5664/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_sql_injection_CVE_2013_0155
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2013-0155/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_remote_code_execution_CVE_2013_0156
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ a\ remote\ code\ execut/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_remote_code_execution_CVE_2013_0269
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :message => /^json\ gem\ 1\.7\.5\ has\ a\ remote\ code/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_xss_sanitize_css_CVE_2013_1855
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 2,
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ a\ vulnerability\ in\ `s/,
      :confidence => 0,
      :file => /sanitized\.html\.erb/
  end

  def test_xml_jruby_parsing_CVE_2013_1856
    if RUBY_PLATFORM == 'java'
      assert_warning :type => :warning,
        :warning_type => "File Access",
        :message => /^Rails\ 3\.2\.9\.rc2 with\ JRuby\ has\ a\ vulnerabili/,
        :confidence => 0,
        :file => /Gemfile/
    end
  end

  def test_denial_of_service_CVE_2013_1854
    assert_warning :type => :warning,
      :warning_code => 55,
      :fingerprint => "2aaf46791b1a8c520cd594aa0b6e382b81b9c8cd9728176a057208e412ec9962",
      :warning_type => "Denial of Service",
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ a\ denial\ of\ service\ vul/,
      :confidence => 1,
      :line => 64,
      :relative_path => "Gemfile.lock"
  end

  def test_i18n_xss_CVE_2013_4491
    assert_warning :type => :warning,
      :warning_code => 63,
      :fingerprint => "7ef985c538fd302e9450be3a61b2177c26bbfc6ccad7a598006802b0f5f8d6ae",
      :warning_type => "Cross-Site Scripting",
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ an\ XSS\ vulnerability/,
      :file => /Gemfile\.lock/,
      :confidence => 1,
      :relative_path => /Gemfile.lock/
  end

  def test_number_to_currency_CVE_2014_0081
    assert_warning :type => :warning,
      :warning_code => 73,
      :fingerprint => "86f945934ed965a47c30705141157c44ee5c546d044f8de7d573bfab456e97ce",
      :warning_type => "Cross-Site Scripting",
      :line => 64,
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ a\ vulnerability\ in\ n/,
      :confidence => 1,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_sql_injection_CVE_2013_6417
    assert_warning :type => :warning,
      :warning_code => 69,
      :fingerprint => "2f63d663e9f35ba60ef81d56ffc4fbf0660fbc2067e728836176bc18f610f77f",
      :warning_type => "SQL Injection",
      :line => 64,
      :file => /Gemfile.lock/,
      :message => /^Rails\ 3\.2\.9\.rc2 contains\ a\ SQL\ injection\ vul/,
      :confidence => 0,
      :relative_path => /Gemfile.lock/,
      :user_input => nil
  end

  def test_denial_of_service_CVE_2014_0082
    assert_warning :type => :warning,
      :warning_code => 75,
      :fingerprint => "99b6df435353f17dff4b0d7dfeb5f21e5c0e8045dc73533e456baf78f1fc2215",
      :warning_type => "Denial of Service",
      :line => 64,
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ a\ denial\ of\ service\ /,
      :confidence => 0,
      :relative_path => "Gemfile.lock",
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

  def test_xml_dos_2015_3227
    assert_warning :type => :warning,
      :warning_code => 88,
      :fingerprint => "ab42647fbdea61e25c4b794e82a8b315054e2fac4328bb3fd4be6a744889a987",
      :warning_type => "Denial of Service",
      :line => 64,
      :message => /^Rails\ 3\.2\.9\.rc2 is vulnerable to denial of service via XML parsing \(CVE-2015-3227\). Upgrade to Rails 3.2.22/,
      :confidence => 1,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_denial_of_service_CVE_2015_0751
    assert_warning :type => :warning,
      :warning_code => 94,
      :fingerprint => "5945a9b096557ee5771c2dd12ea6cbec933b662d169e559f524ba01c44bf2452",
      :warning_type => "Denial of Service",
      :line => 64,
      :message => /^Rails\ 3\.2\.9\.rc2\ is\ vulnerable\ to\ denial\ /,
      :confidence => 1,
      :relative_path => "Gemfile.lock"
  end

  def test_cross_site_scripting_CVE_2016_6316
    assert_warning :type => :warning,
      :warning_code => 102,
      :fingerprint => "1a1b3368951a20d02976c9207e5981df37d1bfa7dbbdb925eecd9013ecfeaa0f",
      :warning_type => "Cross-Site Scripting",
      :line => 64,
      :message => /^Rails\ 3\.2\.9\.rc2\ `content_tag`\ does\ not\ esc/,
      :confidence => 1,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_path_traversal_sprockets_CVE_2018_3760
    assert_warning :type => :warning,
      :warning_code => 108,
      :fingerprint => "f22053251239417f0571439b41f7ea8ff49a7e97f4147578f021a568c2c3ba16",
      :warning_type => "Path Traversal",
      :line => 87,
      :message => /^sprockets\ 2\.1\.3\ has\ a\ path\ traversal\ vul/,
      :confidence => 2,
      :relative_path => "Gemfile.lock",
      :code => nil,
      :user_input => nil
  end

  def test_redirect_1
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 14,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :file => /removal_controller\.rb/
  end

  def test_cross_site_scripting_2
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /_partial\.html\.erb/
  end

  def test_cross_site_scripting_3
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /controller_removed\.html\.erb/
  end

  def test_cross_site_scripting_4
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 2,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /implicit_render\.html\.erb/
  end

  def test_cross_site_scripting_5
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /_form\.html\.erb/
  end

  def test_cross_site_scripting_6
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /mixed_in\.html\.erb/
  end

  def test_cross_site_scripting_7
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 15,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /show\.html\.erb/
  end

  def test_escaped_params_to_json
    assert_no_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 21,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /show\.html\.erb/
  end

  def test_cross_site_scripting_in_slim_param
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 3,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /slimming\.html\.slim/
  end

  def test_cross_site_scripting_in_slim_model
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 4,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /slimming\.html\.slim/
  end

  def test_cross_site_scripting_slim_partial_param
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 6,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /_slimmer\.html\.slim/
  end

  def test_cross_site_scripting_slim_partial_model
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 8,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /_slimmer\.html\.slim/
  end

  def test_mass_assignment_default
    assert_no_warning :type => :model,
      :warning_type => "Attribute Restriction",
      :message => /^Mass\ assignment\ is\ not\ restricted\ using\ /,
      :confidence => 0,
      :file => /account\.rb/
  end

  def test_session_secret_token
    assert_warning :type => :warning,
      :warning_type => "Session Setting",
      :line => 7,
      :message => /^Session\ secret\ should\ not\ be\ included\ in/,
      :confidence => 0,
      :file => /secret_token\.rb/
  end

  def test_model_attr_accessible_admin
    assert_warning :type => :model,
      :warning_code => 60,
      :warning_type => "Mass Assignment",
      :message => "Potentially dangerous attribute available for mass assignment: :admin",
      :confidence => 0, #HIGH
      :file => /user\.rb/
  end

  def test_model_attr_accessible_account_id
    assert_warning :type => :model,
      :warning_code => 60,
      :fingerprint => "add78ac0c12cea9335ad3128f17fd0ff8b0f3772daca1d0d109f9dc02ea2df59",
      :warning_type => "Mass Assignment",
      :message => "Potentially dangerous attribute available for mass assignment: :account_id",
      :confidence => 0,
      :relative_path => "app/models/user.rb"
  end

  def test_model_attr_accessible_account_banned
    assert_warning :type => :model,
      :warning_code => 60,
      :warning_type => "Mass Assignment",
      :message => "Potentially dangerous attribute available for mass assignment: :banned",
      :confidence => 1, #MED
      :file => /account\.rb/
  end

  def test_model_attr_accessible_status_id
    assert_warning :type => :model,
      :warning_code => 60,
      :warning_type => "Mass Assignment",
      :message => "Potentially dangerous attribute available for mass assignment: :status_id",
      :confidence => 2, #LOW
      :file => /user\.rb/
  end

  def test_model_attr_accessible_plan_id
    assert_warning :type => :model,
      :warning_type => "Mass Assignment",
      :message => "Potentially dangerous attribute available for mass assignment: :plan_id",
      :confidence => 2,
      :file => /account\.rb/
  end

  def test_two_distinct_warnings_cant_have_same_fingerprint
    assert_equal report[:model_warnings].map(&:fingerprint), report[:model_warnings].map(&:fingerprint).uniq
  end

  def test_controller_command_injection_direct_from_dependency
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 3,
      :message => /^Possible command injection/,
      :confidence => 0,
      :file => /command_dependency\.rb/,
      :relative_path => "app/controllers/exec_controller/command_dependency.rb",
      :format_code => /params\[:user_input\]/
  end

  def test_model_command_injection_direct_from_dependency
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 3,
      :message => /^Possible command injection/,
      :confidence => 0,
      :file => /command_dependency\.rb/,
      :relative_path => "app/models/user/command_dependency.rb",
      :format_code => /params\[:user_input\]/
  end

  def test_controller_default_routes
    # Test to ensure warnings are generated for loose routes
    assert_warning :type => :controller,
      :warning_type => "Default Routes",
      :message => /`GlobGetController.*get` requests/,
      :fingerprint => "6550aaf3da845a600a9c8fb767d08489679a9e3d89554db3c920ddb4eafcfb8e",
      :file => /routes\.rb/

    assert_warning :type => :controller,
      :warning_type => "Default Routes",
      :message => /`GlobMatchController.*matched` requests/,
      :fingerprint => "fb878909d1635de22ddc819e33e6a75e7f2cce0ff1efd2b7e76b361be88bb73e",
      :file => /routes\.rb/

    assert_warning :type => :controller,
      :warning_type => "Default Routes",
      :message => /`GlobPostController.*post` requests/,
      :fingerprint => "e5364369e3c89e5632aac3645e183037cc18de49f1b67547dca0c7febb6c849f",
      :file => /routes\.rb/

    assert_warning :type => :controller,
      :warning_type => "Default Routes",
      :message => /`GlobPutController.*put` requests/,
      :fingerprint => "b85eeac90866fc04b4bea19c971aed4f2458afe53c908aa7162eb1e46b84f9b6",
      :file => /routes\.rb/

    assert_warning :type => :controller,
      :warning_type => "Default Routes",
      :message => /`FooPostController.*post` requests/,
      :fingerprint => "880355a0a87704aa0d615dea6a175ba78711d1593843a596935f95cac3abc8a5",
      :file => /routes\.rb/

    assert_warning :type => :controller,
      :warning_type => "Default Routes",
      :message => /`FooGetController.*get` requests/,
      :fingerprint => "e4f29dc75741f74327ce95678173d3d5fe296335275f062c06d1348678f6a339",
      :file => /routes\.rb/

    assert_warning :type => :controller,
      :warning_type => "Default Routes",
      :message => /`FooPutController.*put` requests/,
      :fingerprint => "05a92f06689436b7b8189c358baab371de5f0fb7936ab206a11b251b0e5f7570",
      :file => /routes\.rb/

    assert_warning :type => :controller,
      :warning_type => "Default Routes",
      :message => /`BarMatchController.*matched` requests/,
      :fingerprint => "857efc249dfd1b5086dcf79c35e31ef19a7782d03b3beaa12f55f8634b543d2d",
      :file => /routes\.rb/
  end

  def test_command_injection_from_namespaced_model_1
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :class => :"MultiModel::Model1",
      :line => 5,
      :message => /^Possible command injection/,
      :confidence => 0,
      :file => /multi_model\.rb/,
      :relative_path => "app/models/multi_model.rb",
      :format_code => /params\[:user_input\]/
  end

  def test_command_injection_from_namespaced_model_2
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :class => :"MultiModel::Model2",
      :line => 13,
      :message => /^Possible command injection/,
      :confidence => 0,
      :file => /multi_model\.rb/,
      :relative_path => "app/models/multi_model.rb",
      :format_code => /params\[:user_input2\]/
  end

  def test_unmaintained_dependency_rails
    assert_warning check_name: "EOLRails",
      type: :warning,
      warning_code: 120,
      fingerprint: "d84924377155b41e094acae7404ec2e521629d86f97b0ff628e3d1b263f8101c",
      warning_type: "Unmaintained Dependency",
      line: 64,
      message: /^Support\ for\ Rails\ 3\.2\.9\.rc2\ ended\ on\ 201/,
      confidence: 0,
      relative_path: "Gemfile.lock"
  end
end
