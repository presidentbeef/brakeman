abort "Please run using test/test.rb" unless defined? BrakemanTester

Rails2 = BrakemanTester.run_scan "rails2", "Rails 2"

class Rails2Tests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def expected
    if Brakeman::Scanner::RUBY_1_9
      @expected ||= {
        :controller => 1,
        :model => 3,
        :template => 41,
        :warning => 40 }
    else
      @expected ||= {
        :controller => 1,
        :model => 3,
        :template => 41,
        :warning => 41 }
    end
  end

  def report
    Rails2
  end

  def test_no_errors
    assert_equal 0, report[:errors].length
  end

  def test_config_sanity
    assert_equal 'UTC', report[:config][:rails][:time_zone].value
  end

  def test_eval
    assert_warning :warning_type => "Dangerous Eval",
      :line => 40,
      :message => /^User input in eval/,
      :code => /eval\(params\[:dangerous_input\]\)/,
      :file => /home_controller.rb/
  end

  def test_default_routes
    assert_warning :warning_type => "Default Routes",
      :line => 54,
      :message => /All public methods in controllers are available as actions/,
      :file => /routes\.rb/
  end

  def test_command_injection_interpolate
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 34,
      :message => /^Possible command injection/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_command_injection_direct
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 36,
      :message => /^Possible command injection/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :code => /params\[:user_input\]/
  end

  def test_file_access_concatenation
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 24,
      :message => /^Parameter value used in file name/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_mass_assignment
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 54,
      :message => /^Unprotected mass assignment/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_update_attribute_no_mass_assignment
    assert_no_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 26,
      :message => /^Unprotected mass assignment/,
      :confidence => 0,
      :file => /other_controller\.rb/
  end

  def test_mass_assignment_with_or_equals_in_filter
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 127,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_redirect
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 45,
      :message => /^Possible unprotected redirect/,
      :confidence => 0,
      :file => /home_controller\.rb/

    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 182,
      :message => /^Possible unprotected redirect/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_dynamic_render_path
    assert_warning :type => :warning,
      :warning_type => "Dynamic Render Path",
      :line => 59,
      :message => /^Render path contains parameter value near line 59: render/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_dynamic_render_path_high_confidence
    assert_warning :type => :warning,
      :warning_type => "Dynamic Render Path",
      :line => 77,
      :message => /^Render path contains parameter value near line 77: render/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_file_access
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 21,
      :message => /^Parameter value used in file name/,
      :confidence => 0,
      :file => /other_controller\.rb/
  end

  def test_file_access_with_load
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 63,
      :message => /^Parameter value used in file name/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_file_access_load_false
    warnings = find :type => :warning,
      :warning_type => "File Access",
      :line => 64,
      :message => /^Parameter value used in file name/,
      :confidence => 0,
      :file => /home_controller\.rb/

    assert_equal 0, warnings.length, "False positive found."
  end

  def test_session_secret
    assert_warning :type => :warning,
      :warning_type => "Session Setting",
      :line => 9,
      :message => /^Session\ secret\ should\ not\ be\ included\ in/,
      :confidence => 0,
      :file => /session_store\.rb/
  end

  def test_session_cookies
    assert_warning :type => :warning,
      :warning_type => "Session Setting",
      :line => 10,
      :message => /^Session cookies should be set to HTTP on/,
      :confidence => 0,
      :file => /session_store\.rb/
  end

  def test_rails_cve_2012_2660
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-2660/,
      :confidence => 0
  end

  def test_rails_cve_2012_2695
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-2695/,
      :confidence => 0
  end

  def test_sql_injection_find_by_sql
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 28,
      :message => /^Possible SQL injection/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_sql_injection_conditions_local
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 29,
      :message => /^Possible SQL injection/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_sql_injection_params
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 30,
      :message => /^Possible SQL injection/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_sql_injection_named_scope
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 4,
      :message => /^Possible SQL injection near line 4: named_scope\(:phooey/,
      :confidence => 0,
      :file => /user\.rb/
  end

  def test_sql_injection_named_scope_lambda
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 2,
      :message => /^Possible SQL injection near line 2: named_scope\(:dah, lambda/,
      :confidence => 1,
      :file => /user\.rb/
  end

  def test_sql_injection_named_scope_conditional
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 6,
      :message => /^Possible SQL injection near line 6: named_scope\(:with_state, lambda/,
      :confidence => 1,
      :file => /user\.rb/
  end

  def test_sql_injection_in_self_call
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 15,
      :message => /^Possible SQL injection near line 15: self\.find/,
      :confidence => 1,
      :file => /user\.rb/
  end

  def test_sql_user_input_in_find_by
    assert_no_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 116,
      :message => /^Possible SQL injection near line 116: User.find_or_create_by_name/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  # ensure that the warning is generated for the line which contains the input, not
  # the line of the beginning of the string
  def test_sql_user_input_multiline
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 121,
      :message => /^Possible SQL injection near line 121: User.find_by_sql/,
      :confidence => 0,
      :file => /home_controller\.rb/
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

  def test_format_validation
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 2,
      :message => /^Insufficient validation for 'name' using/,
      :confidence => 0,
      :file => /account\.rb/
  end

  def test_unescaped_parameter
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /index\.html\.erb/
  end

  def test_unescaped_request_env
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped request value/,
      :confidence => 0,
      :file => /test_env\.html\.erb/
  end

  def test_params_from_controller
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_params\.html\.erb/
  end

  def test_unrendered_sanitized_params_from_controller
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_sanitized_param\.html\.erb/
  end

  def test_sanitized_params_from_controller
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_sanitized_param\.html\.erb/
  end

  def test_indirect_xss
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 6,
      :message => /^Unescaped parameter value/,
      :confidence => 2,
      :file => /test_params\.html\.erb/
  end

  def test_model_attribute_from_controller
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_model\.html\.erb/
  end

  def test_model_from_controller_indirect_bad
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_model\.html\.erb/
  end

  def test_model_in_link_to
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped model attribute in link_to/,
      :confidence => 0,
      :file => /test_model\.html\.erb/
  end

  def test_escaped_parameter_in_link_to
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 10,
      :message => /^Unescaped parameter value in link_to/,
      :confidence => 1,
      :file => /test_params\.html\.erb/
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
      :line => 9,
      :message => /^Unsafe parameter value in link_to href/,
      :confidence => 1,
      :file => /test_model\.html\.erb/  

    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 11,
      :message => /^Unsafe parameter value in link_to href/,
      :confidence => 1,
      :file => /test_model\.html\.erb/  
  end

  def test_unescaped_body_in_link_to
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped parameter value in link_to/,
      :confidence => 0,
      :file => /test_link_to\.html\.erb/
  end

  def test_filter
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_filter\.html\.erb/
  end

  def test_unescaped_model
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_sql\.html\.erb/
  end

  def test_param_from_filter
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /index\.html\.erb/
  end

  def test_params_from_locals_hash
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_locals\.html\.erb/
  end

  def test_model_attribute_from_collection
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /_user\.html\.erb/
  end

  def test_model_attribute_from_iteration
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_iteration\.html\.erb/
  end

  def test_other_model_attribute_from_iteration
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_iteration\.html\.erb/
  end

  def test_sql_injection_in_template
    assert_no_warning :type => :template,
      :warning_type => "SQL Injection",
      :line => 4,
      :message => /^Possible SQL injection/,
      :confidence => 0,
      :file => /test_sql\.html\.erb/
  end

  def test_sql_injection_call_chain
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 73,
      :message => /^Possible SQL injection near line 73: User.humans.alive.find/,
      :confidence => 0,
      :file => /home_controller\.rb/ 
  end

  def test_sql_injection_merge_conditions
    assert_no_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 22,
      :message => /^Possible SQL injection near line 22: find/,
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
      :line => 5,
      :message => /^Unescaped cookie value/,
      :confidence => 2,
      :file => /test_cookie\.html\.erb/
  end

  def test_cookie_from_controller
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped cookie value/,
      :confidence => 0,
      :file => /test_cookie\.html\.erb/
  end

  #Check for params that look like params[:x][:y]
  def test_params_multidimensional
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 8,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_params\.html\.erb/
  end

  #Check for cookies that look like cookies[:blah][:blah]
  def test_cookies_multidimensional
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped cookie value/,
      :confidence => 0,
      :file => /test_cookie\.html\.erb/
  end

  def test_xss_in_unused_template
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => "Unescaped parameter value near line 1: params[:blah]",
      :confidence => 0,
      :file => /not_used\.html\.erb/
  end

  def test_select_vulnerability
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Upgrade\ to\ Rails\ 3\ or\ use\ options_for_se/,
      :confidence => 1,
      :file => /not_used\.html\.erb/
  end

  def test_explicit_render_template
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped parameter value near line 1: params\[:ba/,
      :confidence => 0,
      :file => /home\/test_render_template\.html\.haml/
  end

  def test_xss_with_or_in_view
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_xss_with_or\.html\.erb/
  end

  def test_xss_with_or_from_action
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_xss_with_or\.html\.erb/
  end

  def test_xss_with_or_from_if_branches
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_xss_with_or\.html\.erb/
  end

  def test_xss_with_nested_or
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_xss_with_or\.html\.erb/
  end

  def test_xss_with_model_in_or
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 9,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /test_xss_with_or\.html\.erb/
  end

  def test_cross_site_scripting_strip_tags
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_strip_tags\.html\.erb/
  end

  def test_xss_content_tag_body
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped\ model\ attribute\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_xss_content_tag_escaped
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 8,
      :message => /^Unescaped\ cookie\ value\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_xss_content_tag_attribute_name
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 11,
      :message => /^Unescaped\ cookie\ value\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_xss_content_tag_attribute_name_even_with_escape_set
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 17,
      :message => /^Unescaped\ model\ attribute\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_cross_site_scripting_escaped_by_default
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 20,
      :message => /^Unescaped\ parameter\ value\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_xss_content_tag_unescaped_on_purpose
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 23,
      :message => /^Unescaped\ model\ attribute\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/
  end

  def test_xss_content_tag_indirect_body
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 26,
      :message => /^Unescaped\ parameter\ value\ in\ content_tag/,
      :confidence => 1,
      :file => /test_content_tag\.html\.erb/
  end

  def test_cross_site_scripting_single_quotes_CVE_2012_3464
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :message => /^All\ Rails\ 2\.x\ versions\ do\ not\ escape\ sin/,
      :confidence => 1,
      :file => /environment\.rb/
  end

  def test_check_send
    assert_warning :type => :warning,
      :warning_type => "Dangerous Send",
      :line => 83,
      :message => /\AUser controlled method execution/,
      :confidence => 0,
      :file => /home_controller\.rb/

    assert_no_warning :type => :warning,
      :warning_type => "Dangerous Send",
      :line => 90,
      :message => /\AUser defined target of method invocation/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_strip_tags_CVE_2011_2931
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :message => /^Versions\ before\ 2\.3\.13\ have\ a\ vulnerabil/,
      :confidence => 0,
      :file => /environment\.rb/
  end

  def test_strip_tags_CVE_2012_3465_high
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_strip_tags\.html\.erb/
  end

  def test_sql_injection_CVE_2012_5664
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /^All\ versions\ of\ Rails\ before\ 3\.0\.18,\ 3\.1/,
      :confidence => 0,
      :file => /environment\.rb/
  end

  def test_sql_injection_CVE_2013_0155
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /^Rails\ 2\.3\.11\ contains\ a\ SQL\ Injection\ Vu/,
      :confidence => 0,
      :file => /environment\.rb/
  end

  def test_remote_code_execution_CVE_2013_0156
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :message => /^Rails\ 2\.3\.11\ has\ a\ remote\ code\ execution/,
      :confidence => 0,
      :file => /environment\.rb/
  end

  def test_remote_code_execution_CVE_2013_0277
    assert_warning :type => :model,
      :warning_type => "Remote Code Execution",
      :message => /^Serialized\ attributes\ are\ vulnerable\ in\ /,
      :confidence => 0,
      :file => /unprotected\.rb/
  end

  def test_remote_code_execution_CVE_2013_0333
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :message => /^Rails\ 2\.3\.11\ has\ a\ serious\ JSON\ parsing\ /,
      :confidence => 0,
      :file => /environment\.rb/
  end

  def test_to_json
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped model attribute in JSON hash/,
      :confidence => 0,
      :file => /test_to_json\.html\.erb/
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped parameter value in JSON hash/,
      :confidence => 0,
      :file => /test_to_json\.html\.erb/
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 11,
      :message => /^Unescaped parameter value in JSON hash/,
      :confidence => 0,
      :file => /test_to_json\.html\.erb/
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 14,
      :message => /^Unescaped parameter value in JSON hash/,
      :confidence => 0,
      :file => /test_to_json\.html\.erb/
  end

  def test_xss_with_params_to_i
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_to_i\.html\.erb/
  end

  def test_xss_with_request_env_to_i
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped\ cookie\ value/,
      :confidence => 2,
      :file => /test_to_i\.html\.erb/
  end

  def test_xss_with_cookie_to_i
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped\ request\ value/,
      :confidence => 0,
      :file => /test_to_i\.html\.erb/
  end

  def test_xss_with_model_attribute_to_i
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 1,
      :file => /test_to_i\.html\.erb/
  end

  def test_dangerous_send_try
    assert_warning :type => :warning,
      :warning_type => "Dangerous Send",
      :line => 155,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_dangerous_send_underscore
    assert_warning :type => :warning,
      :warning_type => "Dangerous Send",
      :line => 156,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_dangerous_public_send
    assert_warning :type => :warning,
      :warning_type => "Dangerous Send",
      :line => 157,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_dangerous_try_on_user_input
    assert_no_warning :type => :warning,
      :warning_type => "Dangerous Send",
      :line => 160,
      :message => /^User\ defined\ target\ of\ method\ invocation/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_unsafe_reflection_constantize
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 89,
      :message => /^Unsafe\ Reflection\ method\ constantize\ cal/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_unsafe_reflection_constantize_2
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 160,
      :message => /^Unsafe\ Reflection\ method\ constantize\ cal/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end
end
