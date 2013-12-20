abort "Please run using test/test.rb" unless defined? BrakemanTester

Rails31 = BrakemanTester.run_scan "rails3.1", "Rails 3.1", :rails3 => true, :parallel_checks => false, :interprocedural => true

class Rails31Tests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    Rails31
  end

  def expected
    @expected ||= {
      :model => 3,
      :template => 23,
      :controller => 4,
      :generic => 77 }
  end

  def test_without_protection
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 47,
      :message => /^Unprotected mass assignment/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_redirect_to_model_attribute
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 98,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_redirect_with_model_instance
    assert_no_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 67,
      :message => /^Possible unprotected redirect/,
      :confidence => 2,
      :file => /users_controller\.rb/
  end

  def test_redirect_to_find_by
    assert_no_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 102,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_redirect_to_decorated_model
    assert_no_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 50,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 2,
      :file => /other_controller\.rb/
  end

  def test_redirect_multiple_values
    assert_no_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 61,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :file => /other_controller\.rb/
  end

  def test_redirect_to_model_as_arg
    assert_no_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 113,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 2,
      :file => /users_controller\.rb/
  end

  def test_redirect_to_model_association
    assert_no_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 117,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_redirect_to_secong_arg
    assert_no_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 121,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 2,
      :file => /users_controller\.rb/
  end

  def test_whitelist_attributes
    assert_no_warning :type => :model,
      :warning_type => "Attribute Restriction",
      :message => /^Mass assignment is not restricted using attr_accessible/,
      :confidence => 0
  end

  #Such as
  #http_basic_authenticate_with :name => "dhh", :password => "secret"
  def test_basic_auth_with_password
    assert_warning :type => :controller,
      :warning_type => "Basic Auth",
      :line => 4,
      :message => /^Basic authentication password stored in source code/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_basic_auth_in_method_with_password
    assert_warning :type => :warning,
      :warning_code => 9,
      :fingerprint => "f2698a4ca148f43a8f77901a57371b6253f450d50ad388de588f32b7dbeb8937",
      :warning_type => "Basic Auth",
      :line => 25,
      :message => /^Basic\ authentication\ password\ stored\ in\ /,
      :confidence => 0,
      :relative_path => "app/controllers/admin_controller.rb"
  end

  def test_translate_bug
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :message => /^Versions before 3.1.2 have a vulnerability/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_rails_cve_2012_2660
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-2660/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_rails_cve_2012_2661
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-2661/,
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

  def test_sql_injection_CVE_2012_5664
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-5664/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_sql_injection_scope_lambda
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 4,
      :message => /^Possible SQL injection near line 4: where/,
      :confidence => 0,
      :file => /user\.rb/
  end

  def test_sql_injection_scope
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 10,
      :message => /^Possible SQL injection near line 10: scope\(:phooey, :conditions =>/,
      :confidence => 0,
      :file => /user\.rb/
  end

  def test_sql_injection_scope_where
    assert_no_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 6,
      :message => /^Possible SQL injection near line 6: where/,
      :confidence => 1,
      :file => /user\.rb/
  end

  def test_sql_injection_scope_lambda_hash
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 8,
      :message => /^Possible SQL injection/,
      :confidence => 1,
      :file => /user\.rb/
  end

  def test_sql_injection_scope_multiline_lambda_where
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 22,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :file => /user\.rb/
  end

  def test_sql_injection_in_order_param
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 4,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /user\.rb/
  end

  def test_sql_injection_in_group_param
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 10,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_interpolated_group_param
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 11,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_in_lock_param
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 67,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_interpolated_lock_param
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 68,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_interpolated_having
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 16,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_interpolated_having_array
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 25,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_interpolated_joins
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 34,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_interpolated_joins_array
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 40,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_in_order_param_product
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 4,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_interpolated_order
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 5,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_in_select_param
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 48,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_interpolated_select
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 49,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end


  def test_sql_injection_in_from_param
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 58,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_interpolated_from
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 59,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_local_interpolation
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 93,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :file => /product\.rb/
  end

  def test_sql_injection_interpolated_where
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 80,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_interpolated_where_array
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 81,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :file => /product\.rb/
  end

  def test_sql_injection_string_concat_select
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 50,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_string_concat_having
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 26,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_with_conditional
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 98,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_in_method_args
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 106,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_with_if_statements
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 130,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_in_calculate
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 139,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_in_minimum
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 140,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_in_maximum
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 141,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_in_average
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 142,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_in_sum
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 143,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_in_select
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 151,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_sql_injection_interpolation_in_first_arg
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 174,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /product\.rb/
  end

  def test_select_vulnerability
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 2,
      :message => /^Upgrade to Rails 3.1.4, 3.1.0 select\(\) helper is vulnerable/,
      :confidence => 1,
      :file => /edit\.html\.erb/
  end

  def test_string_buffer_manipulation_bug
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :message => /^Rails 3.1.0 has a vulnerabilty in SafeBuffer. Upgrade to 3.1.4/,
      :confidence => 1,
      :file => /Gemfile/
  end

  def test_cross_site_request_forgery
    assert_warning :type => :warning,
      :warning_type => "Cross-Site Request Forgery",
      :line => 91,
      :message => /^Use\ whitelist\ \(:only\ =>\ \[\.\.\]\)\ when\ skipp/,
      :confidence => 1,
      :file => /users_controller\.rb/
  end

  def test_authentication_skip_before_filter
    assert_warning :type => :controller,
      :warning_type => "Authentication",
      :line => 3,
      :message => /^Use\ whitelist\ \(:only\ =>\ \[\.\.\]\)\ when\ skipp/,
      :confidence => 1,
      :file => /admin_controller\.rb/
  end

  def test_authentication_skip_filter
    assert_warning :type => :controller,
      :warning_type => "Authentication",
      :line => 5,
      :message => /^Use\ whitelist\ \(:only\ =>\ \[\.\.\]\)\ when\ skipp/,
      :confidence => 1,
      :file => /admin_controller\.rb/
  end

  def test_authentication_skip_require_user
    assert_warning :type => :controller,
      :warning_type => "Authentication",
      :line => 4,
      :message => /^Use\ whitelist\ \(:only\ =>\ \[\.\.\]\)\ when\ skipp/,
      :confidence => 1,
      :file => /admin_controller\.rb/
  end

  def test_controller_mixin
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped parameter value near line 1: params\[:bad\]/,
      :confidence => 0,
      :file => /users\/mixin_template\.html\.erb/
  end

  def test_controller_mixin_default_render
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped parameter value near line 1: params\[:bad\]/,
      :confidence => 0,
      :file => /users\/mixin_default\.html\.erb/
  end

  def test_get_in_resources_block
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /\/a\.html\.erb/
  end

  def test_get_in_controller_block
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /\/b\.html\.erb/
  end

  def test_post_with_just_hash_in_controller_block
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /\/c\.html\.erb/
  end

  def test_put_to_in_controller_block
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /\/d\.html\.erb/
  end

  def test_match_to_route
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /\/e\.html\.erb/
  end

  def test_delete_in_resources_block
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /\/f\.html\.erb/
  end

  def test_route_hash_shorthand
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /\/g\.html\.erb/
  end

  def test_model_name_in_collection_xss
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped model attribute near line 1: User\.new\.bio/,
      :confidence => 0,
      :file => /_bio\.html\.erb/
  end

  def test_xss_helper_params_return
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_less_simple_helpers\.html\.erb/
  end

  def test_xss_helper_with_args
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_less_simple_helpers\.html\.erb/
  end

  def test_xss_helper_assign_ivar
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_less_simple_helpers\.html\.erb/
  end

  def test_xss_helper_assign_ivar_twice
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_assign_twice\.html\.erb/
  end

  def test_xss_helper_model_return
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /test_simple_helper\.html\.erb/
  end

  def test_xss_multiple_exp_in_string_interpolation
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /test_string_interp\.html\.erb/
  end

  def test_cross_site_scripting_select_tag_CVE_2012_3463
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Upgrade\ to\ Rails\ 3\.1\.8,\ 3\.1\.0\ select_tag/,
      :confidence => 0,
      :file => /test_select_tag\.html\.erb/
  end

  def test_cross_site_scripting_single_quotes_CVE_2012_3464
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :message => /^Rails\ 3\.1\.0\ does\ not\ escape\ single\ quote/,
      :confidence => 1,
      :file => /Gemfile/
  end

  def test_file_access_indirect_user_input
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 106,
      :message => /^Parameter\ value\ used\ in\ file\ name/,
      :confidence => 2,
      :file => /users_controller\.rb/
  end

  def test_file_access_in_string_interpolation
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 107,
      :message => /^Cookie\ value\ used\ in\ file\ name/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_file_access_direct_user_input
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 108,
      :message => /^Parameter\ value\ used\ in\ file\ name/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_file_access_model_attribute
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 109,
      :message => /^Model attribute\ used\ in\ file\ name/,
      :confidence => 1,
      :file => /users_controller\.rb/
  end

  def test_CVE_2012_3424
    assert_warning :type => :warning,
      :warning_type => "Denial of Service",
      :message => /^Vulnerability\ in\ digest\ authentication\ \(/,
      :confidence => 2,
      :file => /Gemfile/
  end

  def test_strip_tags_CVE_2012_3465
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :message => /^Rails\ 3\.1\.0\ has\ a\ vulnerability\ in\ strip/,
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

  def test_remote_code_execution_CVE_2013_0156_fix
    assert_no_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :message => /^Rails\ 3\.1\.0\ has\ a\ remote\ code\ execution\ /,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_denial_of_service_CVE_2013_0269
    assert_warning :type => :warning,
      :warning_type => "Denial of Service",
      :message => /^json\ gem\ version\ 1\.5\.4\ has\ a\ symbol\ crea/,
      :confidence => 1,
      :file => /Gemfile/
  end

  def test_xss_sanitize_CVE_2013_1857
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :line => 64,
      :message => /^Rails\ 3\.1\.0\ has\ a\ vulnerability\ in\ sanit/,
      :confidence => 0,
      :file => /other_controller\.rb/
  end

  def test_xss_sanitize_css_CVE_2013_1855
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :line => 65,
      :message => /^Rails\ 3\.1\.0\ has\ a\ vulnerability\ in\ sanitize_css/,
      :confidence => 0,
      :file => /other_controller\.rb/
  end

  def test_xml_jruby_parsing_CVE_2013_1856_workaround
    assert_no_warning :type => :warning,
      :warning_type => "File Access",
      :message => /^Rails\ 3\.1\.0\ with\ JRuby\ has\ a\ vulnerabili/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_denial_of_service_CVE_2013_1854
    assert_warning :type => :warning,
      :warning_code => 55,
      :fingerprint => "2746b8872d4f46676a8c490a7ac906d23f6b11c9d83b6371ff5895139ec7b43b",
      :warning_type => "Denial of Service",
      :message => /^Rails\ 3\.1\.0\ has\ a\ denial\ of\ service\ vul/,
      :confidence => 1,
      :file => /Gemfile/
  end

  def test_denial_of_service_CVE_2013_6414
    assert_warning :type => :warning,
      :warning_code => 64,
      :fingerprint => "a7b00f08e4a18c09388ad017876e3f57d18040ead2816a2091f3301b6f0e5a00",
      :warning_type => "Denial of Service",
      :message => /^Rails\ 3\.1\.0\ has\ a\ denial\ of\ service\ vuln/,
      :confidence => 1,
      :relative_path => "Gemfile"
  end

  def test_number_to_currency_CVE_2013_6415
    assert_warning :type => :warning,
      :warning_code => 65,
      :fingerprint => "813b00b5c58567fb3f32051578b839cb25fc2d827834a30d4b213a4c126202a2",
      :warning_type => "Cross Site Scripting",
      :line => nil,
      :message => /^Rails\ 3\.1\.0\ has\ a\ vulnerability\ in\ numbe/,
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
      :message => /^Rails\ 3\.1\.0\ contains\ a\ SQL\ injection\ vul/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_to_json_with_overwritten_config
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :message => /^Unescaped parameter value in JSON hash/,
      :confidence => 0,
      :line => 1,
      :file => /json_test\.html\.erb/
  end

  def test_cross_site_scripting_in_haml_interp
    assert_no_warning :type => :template,
      :warning_code => 5,
      :fingerprint => "56acfae7db5bda36a971702c819899043e7f62c8623223f353a1ade876454712",
      :warning_type => "Cross Site Scripting",
      :line => 2,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 2,
      :relative_path => "app/views/users/interpolated_value.html.haml"
  end

  def test_arel_table_in_sql
    assert_no_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 46,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /other_controller\.rb/
  end

  def test_to_sql_interpolation
    assert_no_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 181,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :file => /product\.rb/
  end

  def test_sql_injection_update_all
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 140,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_sql_injection_update_all_interpolation
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 141,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_sql_injection_update_all_interp_array
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 142,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_sql_injection_update_all_order_param
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 143,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_sql_injection_update_all_on_where
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 145,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_sql_injection_update_all_on_where_interp
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 146,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_sql_injection_update_all_where_interp_array
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 147,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_sql_injection_in_pluck
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 177,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /users_controller\.rb/
  end

  def test_validates_format
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 2,
      :message => /^Insufficient\ validation\ for\ 'username'\ u/,
      :confidence => 0,
      :file => /account\.rb/
  end

  def test_validates_format_with
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 3,
      :message => /^Insufficient\ validation\ for\ 'phone'\ usin/,
      :confidence => 0,
      :file => /account\.rb/
  end

  def test_validates_format_with_short_regex
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 4,
      :message => /^Insufficient\ validation\ for\ 'first_name'/,
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

  def test_unsafe_reflection_constantize
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 9,
      :message => /^Unsafe\ reflection\ method\ constantize\ cal/,
      :confidence => 0,
      :file => /admin_controller\.rb/
  end


  def test_unsafe_reflection_safe_constantize
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 12,
      :message => /^Unsafe\ reflection\ method\ safe_constantiz/,
      :confidence => 0,
      :file => /admin_controller\.rb/
  end

  def test_unsafe_reflection_qualified_const_get
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 14,
      :message => /^Unsafe\ reflection\ method\ qualified_const/,
      :confidence => 0,
      :file => /admin_controller\.rb/
  end


  def test_unsafe_relection_const_get
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 16,
      :message => /^Unsafe\ reflection\ method\ const_get\ calle/,
      :confidence => 0,
      :file => /admin_controller\.rb/
  end

  def test_unsafe_reflection_constantize_indirect
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 18,
      :message => /^Unsafe\ reflection\ method\ constantize\ cal/,
      :confidence => 1,
      :file => /admin_controller\.rb/
  end

  def test_csv_load
    assert_warning :type => :warning,
      :warning_code => 25,
      :fingerprint => "3b58b691bf7ef0b244ee463aa812e4e6ffe3fe1075c8bd138c0cb5a77f365f41",
      :warning_type => "Remote Code Execution",
      :line => 69,
      :message => /^CSV\.load\ called\ with\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/controllers/other_controller.rb"
  end

  def test_marshal_load
    assert_warning :type => :warning,
      :warning_code => 25,
      :fingerprint => "ecdb984aa40fbe7d42a74ab474a412579b42b36c630bcac640d382e108109437",
      :warning_type => "Remote Code Execution",
      :line => 71,
      :message => /^Marshal\.load\ called\ with\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/controllers/other_controller.rb"
  end

  def test_marshal_restore
    assert_warning :type => :warning,
      :warning_code => 25,
      :fingerprint => "78ef96a81c8b02f97992a7056e4d9696ab238e12bc8a7a3204df29ef11e0a3fe",
      :warning_type => "Remote Code Execution",
      :line => 73,
      :message => /^Marshal\.restore\ called\ with\ model\ attrib/,
      :confidence => 1,
      :relative_path => "app/controllers/other_controller.rb"
  end

  def test_attr_accessible_with_role
    assert_no_warning :type => :model,
      :warning_code => 17,
      :fingerprint => "77c353ad8e5fc9880775ed436bbfa37b005b43aa2978186de92b6916f46fac39",
      :warning_type => "Mass Assignment",
      :message => "Potentially dangerous attribute available for mass assignment: :admin",
      :confidence => 0,
      :relative_path => "app/models/user.rb"
  end

  def test_attr_accessible_not_matching_regex
    assert_no_warning :type => :model,
      :warning_code => 60,
      :fingerprint => "e933f99c33bece852891a466b5b0fc629d9f20ba80ff3bbc42adfd239d5a5b48",
      :warning_type => "Mass Assignment",
      :message => "Potentially dangerous attribute available for mass assignment: :blah_admin_blah",
      :confidence => 0,
      :relative_path => "app/models/account.rb"
  end

  def test_wrong_model_attributes_in_haml
    assert_no_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "8851713f0af477e60090607b814ba68055e4ac1cf19df0628fddd961ff87e763",
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "app/views/other/test_model_in_haml.html.haml"
  end

  def test_right_model_attribute_in_haml
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "3310ef4a4bde8b120fd5d421565ee416af815404e7c116a8069052e8732589d0",
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "app/views/other/test_model_in_haml.html.haml"
  end

  def test_information_disclosure_detailed_exceptions_override
    assert_warning :type => :warning,
      :warning_code => 62,
      :fingerprint => "16f60330426df3603595f5692c7b0916e38c8674a214fef45d7acf248a8db6b3",
      :warning_type => "Information Disclosure",
      :line => 29,
      :message => /^Detailed\ exceptions\ may\ be\ enabled\ in\ 's/,
      :confidence => 1,
      :relative_path => "app/controllers/admin_controller.rb"
  end

  def test_command_injection_interpolation_inside_interpolation
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "5ef09b79bf1d08ccd42e376238f9a618227da4990ea7702a1d4da2e83f4820fe",
      :warning_type => "Command Injection",
      :line => 34,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/admin_controller.rb",
      :user_input => s(:call, nil, :why?)
  end

  def test_command_injection_or_literal_system
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "7de48cc753c090a61ac49a6885bc87198b1a7a72e5629eb2a188b671b95c7f13",
      :warning_type => "Command Injection",
      :line => 42,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/admin_controller.rb"
  end

  def test_command_injection_or_literal_backticks
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "a9ec8db240351f05e084a6acc9f7980d97718eb4cb386d9ea8079d224dfecef9",
      :warning_type => "Command Injection",
      :line => 43,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/admin_controller.rb"
  end

  def test_command_injection_integer_command
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "44d7403b6d2dfe4b74c32b80d924fed3d034637f0e13b3c31193ef9279a674f3",
      :warning_type => "Command Injection",
      :line => 45,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/admin_controller.rb"
  end

  def test_command_injection_integer_exec
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "11ab37cedddb3b4c9cd1c29db6b6ab8cd8a6a0063862448075cc22e9cd8b0882",
      :warning_type => "Command Injection",
      :line => 46,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/admin_controller.rb"
  end
end
