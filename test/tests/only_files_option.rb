require_relative '../test'

class OnlyFilesOptionTests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected
  parallelize_me!

  def expected
    @expected ||= {
      :controller => 8,
      :model => 0,
      :template => 1,
      :generic => 17 }

    if RUBY_PLATFORM == 'java'
      @expected[:generic] += 1
    end

    @expected
  end

  def report
    @@report ||= BrakemanTester.run_scan "rails3.2", "Rails 3.2", { :only_files => ["app/views/users/", "exec_controller.rb", "/app/models/user/"], :skip_files => ["app/views/users/sanitized.html.erb"] }
  end

  def test_escaped_params_to_json
    assert_no_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 21,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /show\.html\.erb/
  end

  def test_cross_site_scripting_slim_partial_param
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 6,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /_slimmer\.html\.slim/
  end

  def test_command_injection_in_exec_controller
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :class => :"ExecController",
      :line => 5,
      :message => /^Possible command injection/,
      :confidence => 0,
      :file => /exec_controller\.rb/
  end

  def test_command_injection_in_user_model_dependency
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :class => :"User",
      :line => 3,
      :message => /^Possible command injection/,
      :confidence => 0,
      :file => /command_dependency\.rb/
  end

  # This is the template that is skipped, should be no warning
  def test_xss_sanitize_css_CVE_2013_1855
    assert_no_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 2,
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ a\ vulnerability\ in\ s/,
      :confidence => 0,
      :file => /sanitized\.html\.erb/
  end

  def test_i18n_xss_CVE_2013_4491
    assert_warning :type => :warning,
      :warning_code => 63,
      :fingerprint => "7ef985c538fd302e9450be3a61b2177c26bbfc6ccad7a598006802b0f5f8d6ae",
      :warning_type => "Cross-Site Scripting",
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ an\ XSS\ vulnerability/,
      :file => /Gemfile\.lock/,
      :confidence => 1,
      :relative_path => /Gemfile/
  end

  def test_denial_of_service_CVE_2013_6414
    assert_warning :type => :warning,
      :warning_code => 64,
      :fingerprint => "ee4938ce7bc4aa6f37b3d993d6fed813de6b15e5c1ada41146563207c395b0c5",
      :warning_type => "Denial of Service",
      :line => 64,
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ a\ denial\ of\ service\ /,
      :confidence => 1,
      :relative_path => "Gemfile.lock",
      :user_input => nil
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
      :message => /^Rails\ 3\.2\.9\.rc2\ is\ vulnerable\ to\ denial\ /,
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

  def test_unmaintained_dependency_rails
    assert_warning check_name: "EOLRails",
      type: :warning,
      warning_code: 120,
      fingerprint: "d84924377155b41e094acae7404ec2e521629d86f97b0ff628e3d1b263f8101c",
      warning_type: "Unmaintained Dependency",
      line: 64,
      message: /^Support\ for\ Rails\ 3\.2\.9\.rc2\ ended\ on\ 201/,
      confidence: 0,
      relative_path: "Gemfile.lock",
      code: nil,
      user_input: nil
  end
end
