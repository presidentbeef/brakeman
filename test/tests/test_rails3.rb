abort "Please run using test/test.rb" unless defined? BrakemanTester

Rails3 = BrakemanTester.run_scan "rails3", "Rails 3", :rails3 => true

class Rails3Tests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected
  
  def report
    Rails3
  end

  def expected
    @expected ||= {
      :controller => 1,
      :model => 5,
      :template => 32,
      :warning => 37
    }
  end

  def test_no_errors
    assert_equal 0, report[:errors].length
  end

  def test_config_sanity
    assert_equal 'utf-8', report[:config][:rails][:encoding].value
  end

  def test_eval_params
    assert_warning :type => :warning,
      :warning_type => "Dangerous Eval",
      :line => 40,
      :message => /^User input in eval near line 40: eval\(pa/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_class_eval_false_positive
    assert_no_warning :type => :warning,
      :warning_type => "Dangerous Eval",
      :line => 13,
      :message => /^User input in eval/,
      :confidence => 0,
      :file => /account\.rb/
  end

  def test_command_injection_params_interpolation
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 34,
      :message => /^Possible command injection near line 34:/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_command_injection_system_params
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 36,
      :message => /^Possible command injection near line 36:/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_command_injection_non_user_input_backticks
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 48,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :file => /other_controller\.rb/
  end

  def test_command_injection_non_user_input_system
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 49,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :file => /other_controller\.rb/
  end

  def test_file_access_concatenation
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 24,
      :message => /^Parameter value used in file name near l/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_file_access_load
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 67,
      :message => /^Parameter value used in file name near l/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_file_access_yaml_load
    assert_no_warning :type => :warning,
      :warning_type => "File Access",
      :line => 106,
      :message => /^Parameter\ value\ used\ in\ file\ name/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_file_access_yaml_parse_file
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 109,
      :message => /^Parameter\ value\ used\ in\ file\ name/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_mass_assignment
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 54,
      :message => /^Unprotected mass assignment near line 54/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_protected_mass_assignment
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 43,
      :message => /^Unprotected mass assignment near line 43: Product.new/,
      :confidence => 2,
      :file => /products_controller\.rb/
  end

  def test_protected_mass_assignment_update
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 62,
      :message => /^Unprotected mass assignment near line 62: Product.find/,
      :confidence => 2,
      :file => /products_controller\.rb/
  end

  def test_update_attribute_no_mass_assignment
    assert_no_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 26,
      :message => /^Unprotected mass assignment near line 26/,
      :confidence => 0,
      :file => /other_controller\.rb/
  end

  def test_redirect
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 45,
      :message => /^Possible unprotected redirect near line /,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_redirect_to_model_instance
    assert_no_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 63,
      :message => /^Possible unprotected redirect near line 63: redirect_to/,
      :confidence => 2,
      :file => /products_controller\.rb/
  end

  def test_redirect_only_path_in_wrong_argument
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 77,
      :message => /^Possible unprotected redirect near line 77: redirect_to\(params\[/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_redirect_url_for_not_only_path
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 83,
      :message => /^Possible unprotected redirect near line 83: redirect_to\(url_for/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_render_path
    assert_warning :type => :warning,
      :warning_type => "Dynamic Render Path",
      :line => 63,
      :message => /^Render path contains parameter value near line 63: render/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_file_access_send_file
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 21,
      :message => /^Parameter value used in file name near l/,
      :confidence => 0,
      :file => /other_controller\.rb/
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
      :message => /^All\ versions\ of\ Rails\ before\ 3\.0\.18,\ 3\.1/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_sql_injection_find_by_sql
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 28,
      :message => /^Possible SQL injection near line 28: Use/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_sql_injection_unknown_variable
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 29,
      :message => /^Possible SQL injection near line 29: Use/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_sql_injection_params
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 30,
      :message => /^Possible SQL injection near line 30: Use/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_sql_injection_non_active_record_model
    assert_no_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 30,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :file => /other_controller\.rb/
  end

  def test_csrf_protection
    assert_warning :type => :controller,
      :warning_type => "Cross-Site Request Forgery",
      :message => /^'protect_from_forgery' should be called /,
      :confidence => 0,
      :file => /application_controller\.rb/
  end

  def test_attribute_restriction
    assert_warning :type => :model,
      :warning_type => "Attribute Restriction",
      :message => /^Mass assignment is not restricted using /,
      :confidence => 0,
      :file => /account, user\.rb/
  end

  def test_attr_protected
    assert_warning :type => :model,
      :warning_type => "Attribute Restriction",
      :message => /^attr_accessible is recommended over attr_protected/,
      :confidence => 2,
      :file => /product\.rb/
  end

  def test_format_validation
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 2,
      :message => /^Insufficient validation for 'name' using/,
      :confidence => 0,
      :file => /account\.rb/
  end

  def test_format_validation_with_z
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 3,
      :message => /^Insufficient validation for 'blah' using/,
      :confidence => 0,
      :file => /account\.rb/
  end

  def test_format_validation_with_a
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 4,
      :message => /^Insufficient validation for 'something' using/,
      :confidence => 0,
      :file => /account\.rb/
  end

  def test_allowable_validation
    results = find :type => :model,
      :warning_type => "Format Validation",
      :line => 5,
      :message => /^Insufficient validation/,
      :confidence => 0,
      :file => /account\.rb/

    assert_equal 0, results.length, "Validation was allowable, should not raise warning"
  end

  def test_allowable_validation_with_Z
    results = find :type => :model,
      :warning_type => "Format Validation",
      :line => 6,
      :message => /^Insufficient validation/,
      :confidence => 0,
      :file => /account\.rb/

    assert_equal 0, results.length, "Validation was allowable, should not raise warning"
  end

  def test_xss_parameter_direct
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped parameter value near line 3: p/,
      :confidence => 0,
      :file => /index\.html\.erb/
  end

  def test_xss_parameter_variable
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped parameter value near line 5: p/,
      :confidence => 0,
      :file => /index\.html\.erb/
  end

  def test_xss_parameter_locals
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Unescaped parameter value near line 4: p/,
      :confidence => 0,
      :file => /test_locals\.html\.erb/
  end

  def test_xss_model_collection
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped model attribute near line 1: User.new.first_name/,
      :confidence => 0,
      :file => /_user\.html\.erb/
  end

  def test_xss_model
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_model\.html\.erb/
  end

  def test_xss_model_known_bad
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 6,
      :message => /^Unescaped model attribute near line 6: a/,
      :confidence => 0,
      :file => /test_model\.html\.erb/
  end

  def test_model_in_link_to
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 8,
      :message => /^Unescaped model attribute in link_to/,
      :confidence => 0,
      :file => /test_model\.html\.erb/
  end

  def test_encoded_href_parameter_in_link_to
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 12,
      :message => /^Unsafe parameter value in link_to href/,
      :confidence => 0,
      :file => /test_params\.html\.erb/
  end  
 
  def test_href_parameter_in_link_to
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 14,
      :message => /^Unsafe parameter value in link_to href/,
      :confidence => 0,
      :file => /test_params\.html\.erb/
 
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 16,
      :message => /^Unsafe parameter value in link_to href/,
      :confidence => 1,
      :file => /test_params\.html\.erb/      
 
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 18,
      :message => /^Unsafe parameter value in link_to href/,
      :confidence => 1,
      :file => /test_params\.html\.erb/            
  end  

  def test_polymorphic_url_in_href
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 10,
      :message => /^Unsafe parameter value in link_to href/,
      :confidence => 1,
      :file => /test_model\.html\.erb/  

    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 12,
      :message => /^Unsafe parameter value in link_to href/,
      :confidence => 1,
      :file => /test_model\.html\.erb/  
  end


  def test_file_access_in_template
    assert_warning :type => :template,
      :warning_type => "File Access",
      :line => 3,
      :message => /^Parameter value used in file name near l/,
      :confidence => 0,
      :file => /test_file_access\.html\.erb/
  end

  def test_xss_cookie_direct
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped cookie value/,
      :confidence => 0,
      :file => /test_cookie\.html\.erb/
  end

  def test_xss_filter
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_filter\.html\.erb/
  end

  def test_xss_iteration
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_iteration\.html\.erb/
  end

  def test_xss_iteration2
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_iteration\.html\.erb/
  end

  def test_unescaped_model
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3, #This should be line 4 :(
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_sql\.html\.erb/
  end

  def test_xss_params
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_params\.html\.erb/
  end

  def test_indirect_xss
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 6,
      :message => /^Unescaped parameter value/,
      :confidence => 2,
      :file => /test_params\.html\.erb/
  end

  def test_sql_injection_in_template
    #SQL injection in controllers should not warn again in views
    assert_no_warning :type => :template,
      :warning_type => "SQL Injection",
      :line => 3, #This should be line 4 :(
      :message => /^Possible SQL injection/,
      :confidence => 0,
      :file => /test_sql\.html\.erb/
  end

  def test_sql_injection_via_if
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 32,
      :message => /^Possible SQL injection near line 32: User.where/,
      :confidence => 0,
      :file => /user\.rb/
  end

  def test_escape_once
    results = find :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped parameter value/,
      :confidence => 2,
      :file => /index\.html\.erb/

    assert_equal 0, results.length, "escape_once is a safe method"
  end

  def test_indirect_cookie
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Unescaped cookie value/,
      :confidence => 2,
      :file => /test_cookie\.html\.erb/
  end

  #Check for params that look like params[:x][:y]
  def test_params_multidimensional
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 10,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_params\.html\.erb/
  end

  #Check for cookies that look like cookies[:blah][:blah]
  def test_cookies_multidimensional
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 6,
      :message => /^Unescaped cookie value/,
      :confidence => 0,
      :file => /test_cookie\.html\.erb/
  end

  def test_default_routes
    assert_warning :warning_type => "Default Routes",
      :line => 97,
      :message => /All public methods in controllers are available as actions/,
      :file => /routes\.rb/
  end

  def test_user_input_in_mass_assignment
    assert_warning :warning_type => "Mass Assignment",
      :line => 58,
      :message => /^Unprotected mass assignment/,
      :confidence => 2,
      :file => /home_controller\.rb/
  end

  def test_mass_assignment_in_chained_call
    assert_warning :warning_type => "Mass Assignment",
      :line => 9,
      :message => /^Unprotected mass assignment near line 9: Account.new/,
      :confidence => 0,
      :file => /account\.rb/
  end

  def test_mass_assign_with_strong_params
    assert_no_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 53,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 0,
      :file => /other_controller\.rb/
  end

  def test_translate_bug
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :message => /^Versions before 3.0.11 have a vulnerability/,
      :confidence => 1,
      :file => /Gemfile/
  end

  def test_model_build
    assert_warning :warning_type => "Mass Assignment",
      :line => 73,
      :message => /^Unprotected mass assignment near line 73: User.new.something.something/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_string_buffer_manipulation_bug
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :message => /^Rails 3\.\d\.\d has a vulnerabilty in SafeBuffer. Upgrade to 3.0.12/,
      :confidence => 1,
      :file => /Gemfile/
  end

  def test_rails3_render_partial
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 15,
      :message => /^Unescaped model attribute near line 15: Product/,
      :confidence => 0,
      :file => /_form\.html\.erb/
  end

  def test_xss_content_tag_raw_content
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 8,
      :message => /^Unescaped\ parameter\ value\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_xss_content_tag_attribute_name
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 14,
      :message => /^Unescaped\ cookie\ value\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_xss_content_tag_attribute_name_even_with_escape
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 20,
      :message => /^Unescaped\ model\ attribute\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_xss_content_tag_unescaped_attribute
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 26,
      :message => /^Unescaped\ model\ attribute\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end 

  def test_xss_content_tag_in_tag_name
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 32,
      :message => /^Unescaped\ parameter\ value\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_cross_site_scripting_model_in_tag_name
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 35,
      :message => /^Unescaped\ model\ attribute\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_cross_site_scripting_request_parameters
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 20,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_params\.html\.erb/
  end

  def test_cross_site_scripting_select_tag_CVE_2012_3463
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Upgrade\ to\ Rails\ 3\.0\.17,\ 3\.0\.3\ select_ta/,
      :confidence => 0,
      :file => /test_select_tag\.html\.erb/
  end

  def test_cross_site_scripting_single_quotes_CVE_2012_3464
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :message => /^Rails\ 3\.0\.3\ does\ not\ escape\ single\ quote/,
      :confidence => 1,
      :file => /Gemfile/
  end

  def test_CVE_2012_3424
    assert_warning :type => :warning,
      :warning_type => "Denial of Service",
      :message => /^Vulnerability\ in\ digest\ authentication\ \(/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_strip_tags_CVE_2012_3465
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :message => /^Versions\ before\ 3\.0\.10\ have\ a\ vulnerabil/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_mail_link_CVE_2011_0446
    assert_warning :type => :template,
      :warning_type => "Mail Link",
      :line => 1,
      :message => /^Vulnerability\ in\ mail_to\ using\ javascrip/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_http_only_session_setting
    assert_warning :type => :warning,
      :warning_type => "Session Setting",
      :line => 3,
      :message => /^Session\ cookies\ should\ be\ set\ to\ HTTP\ on/,
      :confidence => 0,
      :file => /session_store\.rb/
  end

  def test_secure_only_session_setting
    assert_warning :type => :warning,
      :warning_type => "Session Setting",
      :line => 3,
      :message => /^Session\ cookie\ should\ be\ set\ to\ secure\ o/,
      :confidence => 0,
      :file => /session_store\.rb/
  end

  def test_session_secret_token
    assert_warning :type => :warning,
      :warning_type => "Session Setting",
      :line => 7,
      :message => /^Session\ secret\ should\ not\ be\ included\ in/,
      :confidence => 0,
      :file => /secret_token\.rb/
  end
end
