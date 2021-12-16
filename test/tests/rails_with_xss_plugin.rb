require_relative '../test'

class RailsWithXssPluginTests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def expected
    @expected ||= {
      :controller => 1,
      :model => 4,
      :template => 4,
      :generic => 32 }
  end

  def report
    @@report ||= BrakemanTester.run_scan(
      "rails_with_xss_plugin",
      "RailsWithXssPlugin",
      :absolute_paths => true,
      :run_all_checks => true,
      :collapse_mass_assignment => true
    )
  end

  def test_default_routes_1
    assert_warning :type => :warning,
      :warning_type => "Default Routes",
      :line => 52,
      :message => /^All\ public\ methods\ in\ controllers\ are\ av/,
      :confidence => 0,
      :file => /routes\.rb/
  end


  def test_command_injection_2
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 48,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end


  def test_command_injection_3
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 68,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end


  def test_command_injection_4
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 102,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end


  def test_mass_assignment_5
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 47,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 0,
      :file => /posts_controller\.rb/
  end


  def test_mass_assignment_6
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 47,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end


  def test_mass_assignment_7
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 67,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 0,
      :file => /posts_controller\.rb/
  end


  def test_mass_assignment_8
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 71,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_mass_assignment_with_string
    assert_no_warning :type => :warning,
      :warning_code => 17,
      :fingerprint => "2893b1a48ec56548a5a48d38324c5d78f7845066713ad79bb0ec17032672c862",
      :warning_type => "Mass Assignment",
      :line => 97,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 2,
      :relative_path => "app/controllers/other_controller.rb",
      :user_input => nil
  end

  def test_redirect_to_model_instance
    assert_no_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 68,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 2,
      :file => /posts_controller\.rb/
  end


  def test_another_redirect_to_model_instance
    assert_no_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 72,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 2,
      :file => /users_controller\.rb/
  end


  def test_redirect_11
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 95,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end


  def test_rails_cve_2012_2660
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-2660/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_rails_cve_2012_2695
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-2695/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_sql_injection_12
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 126,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end


  def test_cross_site_scripting_13
    assert_warning :type => :warning,
      :warning_type => "Cross-Site Scripting",
      #noline,
      :message => /^Rails\ 2\.3\.x\ using\ the\ rails_xss\ plugin\ h/,
      :confidence => 1,
      :file => /Gemfile/
  end


  def test_cross_site_scripting_14
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 13,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /show\.html\.erb/
  end

  def test_cross_site_scripting_single_quotes_CVE_2012_3464
    assert_no_warning :type => :warning,
      :warning_type => "Cross-Site Scripting",
      :message => /^All\ Rails\ 2\.x\ versions\ do\ not\ escape\ sin/,
      :confidence => 1,
      :file => /environment\.rb/
  end

  def test_dynamic_render_path_15
    assert_no_warning :type => :template,
      :warning_type => "Dynamic Render Path",
      :line => 8,
      :message => /^Render\ path\ is\ dynamic/,
      :confidence => 0,
      :file => /results\.html\.erb/
  end


  def test_sql_injection_16
    assert_no_warning :type => :template,
      :warning_type => "SQL Injection",
      :line => 4,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /results\.html\.erb/
  end


  def test_sql_injection_17
    assert_no_warning :type => :template,
      :warning_type => "SQL Injection",
      :line => 7,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /results\.html\.erb/
  end

  def test_sql_injection_select_value
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "fbf3545b52e589a9f9c25449b3505fadbdec63010664504e7366fbcc5fe6b43a",
      :warning_type => "SQL Injection",
      :line => 134,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :name))
  end

  def test_cross_site_request_forgery_18
    assert_warning :type => :controller,
      :warning_type => "Cross-Site Request Forgery",
      #noline,
      :message => /^`protect_from_forgery`\ should\ be\ called\ /,
      :confidence => 0,
      :file => /application_controller\.rb/
  end

  def test_cross_site_scripting
    assert_warning :type => :template,
      :warning_code => 58,
      :fingerprint => "3ec8749301aa7cdb1d3ec5610120492138060f05d65af0aa53dbb1a3b7c493ac",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Rails\ 2\.3\.14\ has\ a\ vulnerability\ in\ `sani/,
      :confidence => 0,
      :relative_path => "app/views/users/test_sanitize.html.erb",
      :user_input => nil
  end

  def test_cross_site_scripting_sanitize_dupe
    assert_no_warning :type => :template,
      :warning_code => 58,
      :fingerprint => "9d90d446941026c42502e1213ef6d9122a2ad587266cdb002d9f30bb3c77523d",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Rails\ 2\.3\.14\ has\ a\ vulnerability\ in\ `sani/,
      :confidence => 0,
      :relative_path => "app/views/users/test_sanitize.html.erb",
      :user_input => nil
  end

  def test_attribute_restriction_1
    assert_warning :type => :model,
      :warning_code => 19,
      :fingerprint => "180c16a1a0b36556203c87328d46531665774859d07c95d6e31e94322b5395d3",
      :warning_type => "Attribute Restriction",
      :line => 1,
      :message => /^Mass\ assignment\ is\ not\ restricted\ using\ /,
      :confidence => 0,
      :relative_path => "app/models/post.rb",
      :code => nil,
      :user_input => nil
  end

  def test_attribute_restriction_2
    assert_warning :type => :model,
      :warning_code => 19,
      :fingerprint => "b325ae8a4570599cde146875ae86427506befae36a3b4a97ce2223930846fec5",
      :warning_type => "Attribute Restriction",
      :line => 1,
      :message => /^Mass\ assignment\ is\ not\ restricted\ using\ /,
      :confidence => 0,
      :relative_path => "app/models/user.rb",
      :code => nil,
      :user_input => nil
  end

  def test_format_validation_20
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 5,
      :message => /^Insufficient\ validation\ for\ `user_name`\ /,
      :confidence => 0,
      :file => /user\.rb/
  end


  def test_format_validation_21
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 7,
      :message => /^Insufficient\ validation\ for\ `display_nam/,
      :confidence => 0,
      :file => /user\.rb/
  end

  def test_strip_tags_CVE_2012_3465
    assert_warning :type => :warning,
      :warning_type => "Cross-Site Scripting",
      :message => /^All\ Rails\ 2\.x\ versions\ have\ a\ vulnerabil/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_sql_injection_CVE_2012_5664
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-5664/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_to_json
    assert_warning :type => :template,
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped parameter value in JSON hash/,
      :confidence => 0,
      :file => /users\/to_json\.html\.erb/
  end

  def test_session_secret_token
    assert_warning :type => :warning,
      :warning_type => "Session Setting",
      :line => 9,
      :message => /^Session\ secret\ should\ not\ be\ included\ in/,
      :confidence => 0,
      :file => /session_store\.rb/
  end

  def test_absolute_paths
    assert report[:generic_warnings].all? { |w| (Pathname.new w.file).absolute? }
  end

  def test_cross_site_scripting_CVE_2012_1099
    assert_warning :type => :template,
      :warning_code => 22,
      :fingerprint => "4ad12198bfbc84a389e439d3c4cc9c2551e3c2aa7b36182336463ca87e45ec5b",
      :warning_type => "Cross-Site Scripting",
      :line => 18,
      :message => /^Upgrade\ to\ Rails\ 3\ or\ use\ options_for_se/,
      :confidence => 1,
      :relative_path => "app/views/users/index.html.erb",
      :user_input => nil
  end

  def test_cross_site_scripting_html_entities_in_json
    assert_warning :type => :warning,
      :warning_code => 114,
      :fingerprint => "c96eb07567e2a7b0ded7cda123645c4e736d3a1b124bb7c0ffaf5070f53dfcf3",
      :warning_type => "Cross-Site Scripting",
      :line => 21,
      :message => /^HTML\ entities\ in\ JSON\ are\ not\ escaped\ by/,
      :confidence => 1,
      :relative_path => "config/environments/production.rb",
      :code => s(:attrasgn, s(:const, :ActiveSupport), :escape_html_entities_in_json=, s(:false)),
      :user_input => nil
  end

  def test_sql_injection_CVE_2013_0155
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2013-0155/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_parsing_disable_CVE_2013_0156
    assert_no_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :message => /^Rails\ 2\.3\.14\ has\ a\ remote\ code\ execution/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_remote_code_execution_CVE_2013_0156
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :message => /^Parsing\ YAML\ request\ parameters\ enables\ /,
      :confidence => 0
  end

  def test_denial_of_service_CVE_2013_0269
    assert_warning :type => :warning,
      :warning_type => "Denial of Service",
      :message => /^json\ gem\ 1\.1\.0\ has\ a\ symbol\ crea/,
      :confidence => 2,
      :file => /Gemfile/
  end

  def test_json_parsing_workaround_CVE_2013_0333
    assert_no_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :message => /^Rails\ 2\.3\.14\ has\ a\ serious\ JSON\ parsing\ /,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_denial_of_service_CVE_2013_1854
    assert_warning :type => :warning,
      :warning_type => "Denial of Service",
      :message => /^Rails\ 2\.3\.14\ has\ a\ denial\ of\ service\ vul/,
      :confidence => 1,
      :file => /Gemfile/
  end

  def test_sql_injection_CVE_2013_6417
    assert_warning :type => :warning,
      :warning_code => 69,
      :fingerprint => "e1b66f4311771d714a13be519693c540d7e917511a758827d9b2a0a7f958e40f",
      :warning_type => "SQL Injection",
      :line => 3,
      :file => /Gemfile/,
      :message => /^Rails\ 2\.3\.14\ contains\ a\ SQL\ injection\ vu/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_number_to_currency_CVE_2014_0081
    assert_warning :type => :warning,
      :warning_code => 73,
      :fingerprint => "f6981b9c24727ef45040450a1f4b158ae3bc31b4b0343efe853fe12c64881695",
      :warning_type => "Cross-Site Scripting",
      :line => 3,
      :message => /^Rails\ 2\.3\.14\ has\ a\ vulnerability\ in\ numb/,
      :confidence => 1,
      :relative_path => "Gemfile"
  end

  def test_remote_code_execution_CVE_2014_0130
    assert_warning :type => :warning,
      :warning_code => 77,
      :fingerprint => "93393e44a0232d348e4db62276b18321b4cbc9051b702d43ba2fd3287175283c",
      :warning_type => "Remote Code Execution",
      :line => nil,
      :message => /^Rails\ 2\.3\.14\ with\ globbing\ routes\ is\ vul/,
      :confidence => 0,
      :relative_path => "config/routes.rb",
      :user_input => nil
  end

  def test_xml_dos_CVE_2015_3227
    assert_warning :type => :warning,
      :warning_code => 88,
      :fingerprint => "6ad4464dbb2a999591c7be8346dc137c3372b280f4a8b0c024fef91dfebeeb83",
      :warning_type => "Denial of Service",
      :line => 3,
      :message => /^Rails\ 2\.3\.14\ is\ vulnerable\ to\ denial\ of\ /,
      :confidence => 1,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_unmaintained_dependency_rails
    assert_warning check_name: "EOLRails",
      type: :warning,
      warning_code: 120,
      fingerprint: "e9d00416c23870f08d30cfda6ad07e2138e0ce51ab6b684814eb69e789cfa631",
      warning_type: "Unmaintained Dependency",
      line: 3,
      message: /^Support\ for\ Rails\ 2\.3\.14\ ended\ on\ 2013\-0/,
      confidence: 0,
      relative_path: "Gemfile"
  end
end
