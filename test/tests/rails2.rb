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
        :template => 47,
        :generic => 54 }
    else
      @expected ||= {
        :controller => 1,
        :model => 3,
        :template => 47,
        :generic => 55 }
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
      :format_code => /eval\(params\[:dangerous_input\]\)/,
      :file => /home_controller.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_default_routes
    assert_warning :warning_type => "Default Routes",
      :line => 54,
      :message => /All public methods in controllers are available as actions/,
      :file => /routes\.rb/,
      :relative_path => "config/routes.rb"
  end

  def test_command_injection_interpolate
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 34,
      :message => /^Possible command injection/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_command_injection_direct
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 36,
      :message => /^Possible command injection/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb",
      :format_code => /params\[:user_input\]/
  end

  def test_file_access_concatenation
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 24,
      :message => /^Parameter value used in file name/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_mass_assignment
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 54,
      :message => /^Unprotected mass assignment/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_update_attribute_no_mass_assignment
    assert_no_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 26,
      :message => /^Unprotected mass assignment/,
      :confidence => 0,
      :file => /other_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_mass_assignment_with_or_equals_in_filter
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 127,
      :message => /^Unprotected\ mass\ assignment/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_redirect
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 45,
      :message => /^Possible unprotected redirect/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"

    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 182,
      :message => /^Possible unprotected redirect/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_dynamic_render_path
    assert_warning :type => :warning,
      :warning_type => "Dynamic Render Path",
      :line => 59,
      :message => /^Render path contains parameter value near line 59: render/,
      :confidence => 1,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_dynamic_render_path_high_confidence
    assert_warning :type => :warning,
      :warning_type => "Dynamic Render Path",
      :line => 77,
      :message => /^Render path contains parameter value near line 77: render/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_file_access
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 21,
      :message => /^Parameter value used in file name/,
      :confidence => 0,
      :file => /other_controller\.rb/,
      :relative_path => "app/controllers/other_controller.rb"
  end

  def test_file_access_with_load
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 63,
      :message => /^Parameter value used in file name/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_file_access_load_false
    warnings = find :type => :warning,
      :warning_type => "File Access",
      :line => 64,
      :message => /^Parameter value used in file name/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"

    assert_equal 0, warnings.length, "False positive found."
  end

  def test_session_secret
    assert_warning :type => :warning,
      :warning_type => "Session Setting",
      :line => 9,
      :message => /^Session\ secret\ should\ not\ be\ included\ in/,
      :confidence => 0,
      :file => /session_store\.rb/,
      :relative_path => "config/initializers/session_store.rb"
  end

  def test_session_cookies
    assert_warning :type => :warning,
      :warning_type => "Session Setting",
      :line => 10,
      :message => /^Session cookies should be set to HTTP on/,
      :confidence => 0,
      :file => /session_store\.rb/,
      :relative_path => "config/initializers/session_store.rb"
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
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_sql_injection_conditions_local
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 29,
      :message => /^Possible SQL injection/,
      :confidence => 1,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_sql_injection_params
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 30,
      :message => /^Possible SQL injection/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_sql_injection_named_scope
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 4,
      :message => /^Possible SQL injection near line 4: named_scope\(:phooey/,
      :confidence => 0,
      :file => /user\.rb/,
      :relative_path => "app/models/user.rb"
  end

  def test_sql_injection_named_scope_lambda
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 2,
      :message => /^Possible SQL injection near line 2: named_scope\(:dah, lambda/,
      :confidence => 1,
      :file => /user\.rb/,
      :relative_path => "app/models/user.rb"
  end

  def test_sql_injection_named_scope_conditional
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 6,
      :message => /^Possible SQL injection near line 6: named_scope\(:with_state, lambda/,
      :confidence => 1,
      :file => /user\.rb/,
      :relative_path => "app/models/user.rb"
  end

  def test_sql_injection_in_self_call
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 15,
      :message => /^Possible SQL injection near line 15: self\.find/,
      :confidence => 1,
      :file => /user\.rb/,
      :relative_path => "app/models/user.rb"
  end

  def test_sql_user_input_in_find_by
    assert_no_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 116,
      :message => /^Possible SQL injection near line 116: User.find_or_create_by_name/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  # ensure that the warning is generated for the line which contains the input, not
  # the line of the beginning of the string
  def test_sql_user_input_multiline
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 121,
      :message => /^Possible SQL injection near line 121: User.find_by_sql/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_sql_injection_false_positive_quote_value
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "6ea8fe3abe8eac86e5ecb790b53fb064b1152b2574b14d9354a40d07269a952e",
      :warning_type => "SQL Injection",
      :line => 30,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/user.rb",
      :user_input => s(:call, s(:call, s(:str, "DELETE FROM cool_table WHERE cool_id="), :+, s(:call, nil, :quote_value, s(:call, s(:self), :cool_id))), :+, s(:str, "  AND my_id="))
  end

  def test_sql_injection_sanitize_sql
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "7481ff666ae949b8442400cf516615ce8b04b87f7e11e33e29d4ad1303d24dd0",
      :warning_type => "SQL Injection",
      :line => 26,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/user.rb",
      :user_input => s(:call, s(:str, "select * from cool_table where stuff = "), :+, s(:call, s(:self), :sanitize_sql, s(:lvar, :input)))
  end

  def test_csrf_protection
    assert_warning :type => :controller,
      :warning_type => "Cross-Site Request Forgery",
      :message => /^'protect_from_forgery' should be called /,
      :confidence => 0,
      :file => /application_controller\.rb/,
      :relative_path => "app/controllers/application_controller.rb"
  end

  def test_attribute_restriction
    assert_warning :type => :model,
      :warning_type => "Attribute Restriction",
      :warning_code => Brakeman::WarningCodes::Codes[:no_attr_accessible],
      :message => /^Mass assignment is not restricted using /,
      :confidence => 0,
      :file => /account, user\.rb/,
      :relative_path => "app/models/account, user.rb" #TODO: kinda broken
  end

  def test_format_validation
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 2,
      :message => /^Insufficient validation for 'name' using/,
      :confidence => 0,
      :file => /account\.rb/,
      :relative_path => "app/models/account.rb"
  end

  def test_unescaped_parameter
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /index\.html\.erb/,
      :relative_path => "app/views/home/index.html.erb"
  end

  def test_unescaped_request_env
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped request value/,
      :confidence => 0,
      :file => /test_env\.html\.erb/,
      :relative_path => "app/views/other/test_env.html.erb"
  end

  def test_params_from_controller
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_params\.html\.erb/,
      :relative_path => "app/views/home/test_params.html.erb"
  end

  def test_unrendered_sanitized_params_from_controller
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_sanitized_param\.html\.erb/,
      :relative_path => "app/views/home/test_sanitized_param.html.erb"
  end

  def test_sanitized_params_from_controller
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_sanitized_param\.html\.erb/,
      :relative_path => "app/views/home/test_sanitized_param.html.erb"
  end

  def test_indirect_xss
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 6,
      :message => /^Unescaped parameter value/,
      :confidence => 2,
      :file => /test_params\.html\.erb/,
      :relative_path => "app/views/home/test_params.html.erb"
  end

  def test_model_attribute_from_controller
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_model\.html\.erb/,
      :relative_path => "app/views/home/test_model.html.erb"
  end

  def test_model_from_controller_indirect_bad
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_model\.html\.erb/,
      :relative_path => "app/views/home/test_model.html.erb"
  end

  def test_model_in_link_to
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped model attribute in link_to/,
      :confidence => 0,
      :file => /test_model\.html\.erb/,
      :relative_path => "app/views/home/test_model.html.erb"
  end

  def test_indirect_model_in_link_to
    assert_warning :type => :template,
      :warning_code => 3,
      :fingerprint => "8941c902e7c71d0df4ebb1888c8ed9ac99affaf385be657838452ac3eefe563c",
      :warning_type => "Cross Site Scripting",
      :line => 9,
      :message => /^Unescaped\ model\ attribute\ in\ l/,
      :confidence => 1,
      :relative_path => "app/views/home/test_link_to.html.erb"
  end

  def test_escaped_parameter_in_link_to
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 10,
      :message => /^Unescaped parameter value in link_to/,
      :confidence => 1,
      :file => /test_params\.html\.erb/,
      :relative_path => "app/views/home/test_params.html.erb"
  end

  def test_encoded_href_parameter_in_link_to
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 12,
      :message => /^Unsafe parameter value in link_to href/,
      :confidence => 0,
      :file => /test_params\.html\.erb/,
      :relative_path => "app/views/home/test_params.html.erb"
  end

  def test_href_parameter_in_link_to
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 14,
      :message => /^Unsafe parameter value in link_to href/,
      :confidence => 0,
      :file => /test_params\.html\.erb/,
      :relative_path => "app/views/home/test_params.html.erb"

    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 16,
      :message => /^Unsafe parameter value in link_to href/,
      :confidence => 1,
      :file => /test_params\.html\.erb/,
      :relative_path => "app/views/home/test_params.html.erb"

    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 18,
      :message => /^Unsafe parameter value in link_to href/,
      :confidence => 1,
      :file => /test_params\.html\.erb/,
      :relative_path => "app/views/home/test_params.html.erb"
  end

  def test_polymorphic_url_in_href
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 9,
      :message => /^Unsafe parameter value in link_to href/,
      :confidence => 1,
      :file => /test_model\.html\.erb/,
      :relative_path => "app/views/home/test_model.html.erb"

    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 11,
      :message => /^Unsafe parameter value in link_to href/,
      :confidence => 1,
      :file => /test_model\.html\.erb/,
      :relative_path => "app/views/home/test_model.html.erb"
  end

  def test_unescaped_body_in_link_to
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped parameter value in link_to/,
      :confidence => 0,
      :file => /test_link_to\.html\.erb/,
      :relative_path => "app/views/home/test_link_to.html.erb"
  end

  def test_filter
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_filter\.html\.erb/,
      :relative_path => "app/views/home/test_filter.html.erb"
  end

  def test_unescaped_model
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_sql\.html\.erb/,
      :relative_path => "app/views/home/test_sql.html.erb"
  end

  def test_param_from_filter
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /index\.html\.erb/,
      :relative_path => "app/views/home/index.html.erb"
  end

  def test_params_from_locals_hash
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /app\/views\/other\/test_locals\.html\.erb/,
      :relative_path => "app/views/other/test_locals.html.erb"
  end

  def test_model_attribute_from_collection
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /_user\.html\.erb/,
      :relative_path => "app/views/other/_user.html.erb"
  end

  def test_model_attribute_from_iteration
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_iteration\.html\.erb/,
      :relative_path => "app/views/other/test_iteration.html.erb"
  end

  def test_other_model_attribute_from_iteration
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Unescaped model attribute/,
      :confidence => 0,
      :file => /test_iteration\.html\.erb/,
      :relative_path => "app/views/other/test_iteration.html.erb"
  end

  def test_sql_injection_in_template
    assert_no_warning :type => :template,
      :warning_type => "SQL Injection",
      :line => 4,
      :message => /^Possible SQL injection/,
      :confidence => 0,
      :file => /test_sql\.html\.erb/,
      :relative_path => "app/views/home/test_sql.html.erb"
  end

  def test_sql_injection_call_chain
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 73,
      :message => /^Possible SQL injection near line 73: User.humans.alive.find/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_sql_injection_merge_conditions
    assert_no_warning :type => :warning,
      :warning_type => "SQL Injection",
      :line => 22,
      :message => /^Possible SQL injection near line 22: find/,
      :confidence => 0,
      :file => /user\.rb/,
      :relative_path => "app/models/user.rb"
  end

  def test_sql_injection_active_record_base_connection
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "37885d589fc5c41553dcc38b36b506c2e508d1f37ce040eb6dca92a958f858fb",
      :warning_type => "SQL Injection",
      :line => 26,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/user.rb",
      :user_input => s(:lvar, :value)
  end

  def test_escape_once
    results = find :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped parameter value/,
      :confidence => 2,
      :file => /index\.html\.erb/,
      :relative_path => "app/views/home/index.html.erb"

    assert_equal 0, results.length, "escape_once is a safe method"
  end

  def test_indirect_cookie
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped cookie value/,
      :confidence => 2,
      :file => /test_cookie\.html\.erb/,
      :relative_path => "app/views/home/test_cookie.html.erb"
  end

  def test_cookie_from_controller
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped cookie value/,
      :confidence => 0,
      :file => /test_cookie\.html\.erb/,
      :relative_path => "app/views/home/test_cookie.html.erb"
  end

  #Check for params that look like params[:x][:y]
  def test_params_multidimensional
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 8,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /test_params\.html\.erb/,
      :relative_path => "app/views/home/test_params.html.erb"
  end

  #Check for cookies that look like cookies[:blah][:blah]
  def test_cookies_multidimensional
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped cookie value/,
      :confidence => 0,
      :file => /test_cookie\.html\.erb/,
      :relative_path => "app/views/home/test_cookie.html.erb"
  end

  def test_xss_in_unused_template
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => "Unescaped parameter value near line 1: params[:blah]",
      :confidence => 0,
      :file => /not_used\.html\.erb/,
      :relative_path => "app/views/other/not_used.html.erb"
  end

  def test_select_vulnerability
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Upgrade\ to\ Rails\ 3\ or\ use\ options_for_se/,
      :confidence => 1,
      :file => /not_used\.html\.erb/,
      :relative_path => "app/views/other/not_used.html.erb"
  end

  def test_explicit_render_template
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped parameter value near line 1: params\[:ba/,
      :confidence => 0,
      :file => /home\/test_render_template\.html\.haml/,
      :relative_path => "app/views/home/test_render_template.html.haml"
  end

  def test_xss_with_or_in_view
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_xss_with_or\.html\.erb/,
      :relative_path => "app/views/home/test_xss_with_or.html.erb"
  end

  def test_xss_with_or_from_action
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_xss_with_or\.html\.erb/,
      :relative_path => "app/views/home/test_xss_with_or.html.erb"
  end

  def test_xss_with_or_from_if_branches
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_xss_with_or\.html\.erb/,
      :relative_path => "app/views/home/test_xss_with_or.html.erb"
  end

  def test_xss_with_nested_or
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_xss_with_or\.html\.erb/,
      :relative_path => "app/views/home/test_xss_with_or.html.erb"
  end

  def test_xss_with_model_in_or
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 9,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /test_xss_with_or\.html\.erb/,
      :relative_path => "app/views/home/test_xss_with_or.html.erb"
  end

  def test_cross_site_scripting_strip_tags
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_strip_tags\.html\.erb/,
      :relative_path => "app/views/home/test_strip_tags.html.erb"
  end

  def test_xss_content_tag_body
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped\ model\ attribute\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/,
      :relative_path => "app/views/home/test_content_tag.html.erb"
  end

  def test_xss_content_tag_escaped
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 8,
      :message => /^Unescaped\ cookie\ value\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/,
      :relative_path => "app/views/home/test_content_tag.html.erb"
  end

  def test_xss_content_tag_attribute_name
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 11,
      :message => /^Unescaped\ cookie\ value\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/,
      :relative_path => "app/views/home/test_content_tag.html.erb"
  end

  def test_xss_content_tag_attribute_name_even_with_escape_set
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 17,
      :message => /^Unescaped\ model\ attribute\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/,
      :relative_path => "app/views/home/test_content_tag.html.erb"
  end

  def test_cross_site_scripting_escaped_by_default
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 20,
      :message => /^Unescaped\ parameter\ value\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/,
      :relative_path => "app/views/home/test_content_tag.html.erb"
  end

  #Uh...maybe this shouldn't be a warning
  def test_cross_site_scripting_in_sanitize_method
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 2,
      :file => /not_used\.html\.erb/,
      :relative_path => "app/views/other/not_used.html.erb"
  end

  def test_xss_content_tag_unescaped_on_purpose
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 23,
      :message => /^Unescaped\ model\ attribute\ in\ content_tag/,
      :confidence => 0,
      :file => /test_content_tag\.html\.erb/,
      :relative_path => "app/views/home/test_content_tag.html.erb"
  end

  def test_xss_content_tag_indirect_body
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 26,
      :message => /^Unescaped\ parameter\ value\ in\ content_tag/,
      :confidence => 1,
      :file => /test_content_tag\.html\.erb/,
      :relative_path => "app/views/home/test_content_tag.html.erb"
  end

  def test_cross_site_scripting_single_quotes_CVE_2012_3464
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :message => /^All\ Rails\ 2\.x\ versions\ do\ not\ escape\ sin/,
      :confidence => 1,
      :file => /environment\.rb/,
      :relative_path => "config/environment.rb"
  end

  def test_check_send
    assert_warning :type => :warning,
      :warning_type => "Dangerous Send",
      :line => 83,
      :message => /\AUser controlled method execution/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"

    assert_no_warning :type => :warning,
      :warning_code => 23,
      :warning_type => "Dangerous Send",
      :line => 84,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :relative_path => "app/controllers/home_controller.rb"

    assert_no_warning :type => :warning,
      :warning_type => "Dangerous Send",
      :line => 90,
      :message => /\AUser defined target of method invocation/,
      :confidence => 1,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_strip_tags_CVE_2011_2931
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :message => /^Versions\ before\ 2\.3\.13\ have\ a\ vulnerabil/,
      :confidence => 0,
      :file => /environment\.rb/,
      :relative_path => "config/environment.rb"
  end

  def test_strip_tags_CVE_2012_3465_high
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_strip_tags\.html\.erb/,
      :relative_path => "app/views/home/test_strip_tags.html.erb"
  end

  def test_sql_injection_CVE_2012_5664
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-5664/,
      :confidence => 0,
      :file => /environment\.rb/,
      :relative_path => "config/environment.rb"
  end

  def test_sql_injection_CVE_2013_0155
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2013-0155/,
      :confidence => 0,
      :file => /environment\.rb/,
      :relative_path => "config/environment.rb"
  end

  def test_remote_code_execution_CVE_2013_0156
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :message => /^Rails\ 2\.3\.11\ has\ a\ remote\ code\ execution/,
      :confidence => 0,
      :file => /environment\.rb/,
      :relative_path => "config/environment.rb"
  end

  def test_remote_code_execution_CVE_2013_0277
    assert_warning :type => :model,
      :warning_type => "Remote Code Execution",
      :message => /^Serialized\ attributes\ are\ vulnerable\ in\ /,
      :confidence => 0,
      :file => /unprotected\.rb/,
      :relative_path => "app/models/unprotected.rb"
  end

  def test_remote_code_execution_CVE_2013_0333
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :message => /^Rails\ 2\.3\.11\ has\ a\ serious\ JSON\ parsing\ /,
      :confidence => 0,
      :file => /environment\.rb/,
      :relative_path => "config/environment.rb"
  end

  def test_xss_sanitize_CVE_2013_1857
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Rails\ 2\.3\.11\ has\ a\ vulnerability\ in\ sani/,
      :confidence => 0,
      :file => /not_used\.html\.erb/,
      :relative_path => "app/views/other/not_used.html.erb"
  end

  def test_denial_of_service_CVE_2013_1854
    assert_warning :type => :warning,
      :warning_type => "Denial of Service",
      :message => /^Rails\ 2\.3\.11\ has\ a\ denial\ of\ service\ vul/,
      :confidence => 1,
      :file => /environment\.rb/,
      :relative_path => "config/environment.rb"
  end

  def test_number_to_currency_CVE_2014_0081
    assert_warning :type => :warning,
      :warning_code => 73,
      :fingerprint => "dd82650c29c3ec7b77437c32d394641744208b42b2aeb673d54e5f42c51e6c33",
      :warning_type => "Cross Site Scripting",
      :line => nil,
      :message => /^Rails\ 2\.3\.11\ has\ a\ vulnerability\ in\ numb/,
      :confidence => 1,
      :relative_path => "config/environment.rb",
      :user_input => nil
  end

  def test_sql_injection_CVE_2013_6417
    assert_warning :type => :warning,
      :warning_code => 69,
      :fingerprint => "378978cda99add8404dd38db466f6ffa0b824ea8c57270d98869241a240d12a6",
      :warning_type => "SQL Injection",
      :line => nil,
      :message => /^Rails\ 2\.3\.11\ contains\ a\ SQL\ injection\ vu/,
      :confidence => 0,
      :relative_path => "config/environment.rb",
      :user_input => nil
  end

  def test_to_json
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped model attribute in JSON hash/,
      :confidence => 0,
      :file => /test_to_json\.html\.erb/,
      :relative_path => "app/views/home/test_to_json.html.erb"

    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped parameter value in JSON hash/,
      :confidence => 0,
      :file => /test_to_json\.html\.erb/,
      :relative_path => "app/views/home/test_to_json.html.erb"

    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 11,
      :message => /^Unescaped parameter value in JSON hash/,
      :confidence => 0,
      :file => /test_to_json\.html\.erb/,
      :relative_path => "app/views/home/test_to_json.html.erb"

    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 14,
      :message => /^Unescaped parameter value in JSON hash/,
      :confidence => 0,
      :file => /test_to_json\.html\.erb/,
      :relative_path => "app/views/home/test_to_json.html.erb"
  end

  def test_xss_with_params_to_i
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /test_to_i\.html\.erb/,
      :relative_path => "app/views/home/test_to_i.html.erb"
  end

  def test_xss_with_request_env_to_i
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 5,
      :message => /^Unescaped\ cookie\ value/,
      :confidence => 2,
      :file => /test_to_i\.html\.erb/,
      :relative_path => "app/views/home/test_to_i.html.erb"
  end

  def test_xss_with_cookie_to_i
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped\ request\ value/,
      :confidence => 0,
      :file => /test_to_i\.html\.erb/,
      :relative_path => "app/views/home/test_to_i.html.erb"
  end

  def test_xss_with_model_attribute_to_i
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 7,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 1,
      :file => /test_to_i\.html\.erb/,
      :relative_path => "app/views/home/test_to_i.html.erb"
  end

  def test_cross_site_scripting_unresolved_model_id
    assert_no_warning :type => :template,
      :warning_code => 2,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /_models\.html\.erb/
  end

  def test_cross_site_scripting_in_layout_for_dupe
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "5d9a5790dbcd6ae68a11e8cdb791a8be9585bf0f75b18ef1f763c6965f55e431",
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/layouts/thing.html.erb"
  end

  def test_cross_site_scripting_in_layout_weak_dupe
    assert_no_warning :type => :template,
      :warning_code => 5,
      :fingerprint => "56fa0dc161d310062ae4717dd70515269b776fe532352e59f72ed2cdc4932153",
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 2,
      :relative_path => "app/views/layouts/thing.html.erb"
  end

  def test_cross_site_scripting_in_haml
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "702f9bae476402bb2614794276083849342540bd8b5e8f2fc35b15b40e9f34fc",
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "app/views/other/test_haml_stuff.html.haml",
      :user_input => nil
  end

  def test_cross_site_scripting_in_haml2
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "79cbc87a06ad9247362be97ba4b6cc12b9619fd0f68d468b81cbed376bfbcc5c",
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "app/views/other/test_haml_stuff.html.haml",
      :user_input => nil
  end

  def test_dangerous_send_try
    assert_warning :type => :warning,
      :warning_type => "Dangerous Send",
      :line => 155,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_dangerous_send_underscore
    assert_warning :type => :warning,
      :warning_type => "Dangerous Send",
      :line => 156,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_dangerous_public_send
    assert_warning :type => :warning,
      :warning_type => "Dangerous Send",
      :line => 157,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_dangerous_try_on_user_input
    assert_no_warning :type => :warning,
      :warning_type => "Dangerous Send",
      :line => 160,
      :message => /^User\ defined\ target\ of\ method\ invocation/,
      :confidence => 1,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_unsafe_reflection_constantize
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 89,
      :message => /^Unsafe\ reflection\ method\ constantize\ cal/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"

    # This is same call, copied to template
    assert_no_warning :type => :template,
      :warning_code => 24,
      :warning_type => "Remote Code Execution",
      :line => 1,
      :message => /^Unsafe\ reflection\ method\ constantize\ cal/,
      :confidence => 0,
      :relative_path => "app/views/home/test_send_target.html.erb"
  end

  def test_unsafe_reflection_constantize_2
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :line => 160,
      :message => /^Unsafe\ reflection\ method\ constantize\ cal/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_unsafe_symbol_creation
    [41,42].each do |line|
      assert_warning :type => :warning,
        :warning_type => "Denial of Service",
        :line => line,
        :message => /^Symbol\ conversion\ from\ unsafe\ string/,
        :confidence => 0,
        :file => /application_controller\.rb/,
        :relative_path => "app/controllers/application_controller.rb"
     end
  end

  def test_unsafe_symbol_creation_2
    assert_warning :type => :warning,
      :warning_type => "Denial of Service",
      :line => 83,
      :message => /^Symbol\ conversion\ from\ unsafe\ string/,
      :confidence => 0,
      :file => /home_controller\.rb/,
      :relative_path => "app/controllers/home_controller.rb"
  end

  def test_unsafe_symbol_creation_3
    assert_warning :type => :warning,
      :warning_type => "Denial of Service",
      :line => 29,
      :message => /^Symbol\ conversion\ from\ unsafe\ string/,
      :confidence => 1,
      :file => /application_controller\.rb/,
      :relative_path => "app/controllers/application_controller.rb"
  end

  def test_unsafe_symbol_creation_4
    assert_warning :type => :warning,
      :warning_type => "Denial of Service",
      :line => 86,
      :message => /^Symbol\ conversion\ from\ unsafe\ string\ \(pa/,
      :confidence => 0,
      :file => /other_controller\.rb/,
      :relative_path => "app/controllers/other_controller.rb"
  end

  def test_unsafe_symbol_creation_5
    assert_warning :type => :warning,
      :warning_type => "Denial of Service",
      :line => 88,
      :message => /^Symbol\ conversion\ from\ unsafe\ string\ \(pa/,
      :confidence => 1,
      :file => /other_controller\.rb/,
      :relative_path => "app/controllers/other_controller.rb"
  end

  def test_unsafe_symbol_creation_6
    assert_warning :type => :warning,
      :warning_type => "Denial of Service",
      :line => 44,
      :message => /^Symbol\ conversion\ from\ unsafe\ string\ \(pa/,
      :confidence => 1,
      :file => /application_controller\.rb/,
      :relative_path => "app/controllers/application_controller.rb"
  end

  def test_regex_dos
    assert_warning :type => :warning,
      :warning_code => 76,
      :fingerprint => "4ac4f6438b6ad6deb9dfec0d96a47f071853396b4325dad85ebb6aa87b309c98",
      :warning_type => "Denial of Service",
      :line => 74,
      :message => /^Parameter\ value\ used\ in\ regex/,
      :confidence => 0,
      :relative_path => "app/controllers/other_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :regex))
  end

  def test_indirect_regex_dos
    assert_warning :type => :warning,
      :warning_code => 76,
      :fingerprint => "b7a197708a04abd2d8f0ca402f3bb0e8690f57685814e09440d1946ba279b14f",
      :warning_type => "Denial of Service",
      :line => 82,
      :message => /^Parameter\ value\ used\ in\ regex/,
      :confidence => 2,
      :relative_path => "app/controllers/other_controller.rb",
      :user_input => s(:call, s(:params), :[], s(:lit, :regex))
  end

  def test_unsafe_symbol_creation_from_param
    assert_warning :type => :warning,
      :warning_code => 59,
      :fingerprint => "b9c29fc37080f827527feb53f29d618b91d9a5aaac9047383baf46361f08c4cc",
      :warning_type => "Denial of Service",
      :line => 49,
      :message => /^Symbol\ conversion\ from\ unsafe\ string\ \(pa/,
      :confidence => 0,
      :relative_path => "app/controllers/other_controller.rb"
  end

  def test_to_sym_duplicate_as_argument
    assert_no_warning :type => :warning,
      :warning_code => 59,
      :fingerprint => "b9c29fc37080f827527feb53f29d618b91d9a5aaac9047383baf46361f08c4cc",
      :warning_type => "Denial of Service",
      :line => 53,
      :message => /^Symbol\ conversion\ from\ unsafe\ string\ \(pa/,
      :confidence => 0,
      :relative_path => "app/controllers/other_controller.rb"
  end

  def test_to_sym_duplicate_as_target
    assert_no_warning :type => :warning,
      :warning_code => 59,
      :fingerprint => "b9c29fc37080f827527feb53f29d618b91d9a5aaac9047383baf46361f08c4cc",
      :warning_type => "Denial of Service",
      :line => 54,
      :message => /^Symbol\ conversion\ from\ unsafe\ string\ \(pa/,
      :confidence => 0,
      :relative_path => "app/controllers/other_controller.rb"
  end

  def test_ignored_sql_warning
    assert_no_warning :type => :template,
      :warning_code => 0,
      :fingerprint => "f2fa1da45eea252150f6920454822bda3ed5c83a2c376c1296a98037969dd45f",
      :warning_type => "SQL Injection",
      :line => 2,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/views/other/ignore_me.html.erb"
  end

  def test_ignored_xss_warning
    assert_no_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "6300805e44167e6c3446efbd06b97206928855a2bfc6e1f3e61c097795956b13",
      :warning_type => "Cross Site Scripting",
      :line => 2,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "app/views/other/ignore_me.html.erb"
  end
end

Rails2WithOptions = BrakemanTester.run_scan "rails2", "Rails 2", :collapse_mass_assignment => false

class Rails2WithOptionsTests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def expected
    if Brakeman::Scanner::RUBY_1_9
      @expected ||= {
        :controller => 1,
        :model => 4,
        :template => 47,
        :generic => 54 }
    else
      @expected ||= {
        :controller => 1,
        :model => 4,
        :template => 47,
        :generic => 55 }
    end
  end

  def report
    Rails2WithOptions
  end

  def test_no_errors
    assert_equal 0, report[:errors].length
  end

  def test_attribute_restriction
    assert_warning :type => :model,
      :warning_type => "Attribute Restriction",
      :warning_code => Brakeman::WarningCodes::Codes[:no_attr_accessible],
      :message => /^Mass assignment is not restricted using /,
      :confidence => 0,
      :file => /account\.rb/
    assert_warning :type => :model,
      :warning_type => "Attribute Restriction",
      :warning_code => Brakeman::WarningCodes::Codes[:no_attr_accessible],
      :message => /^Mass assignment is not restricted using /,
      :confidence => 0,
      :file => /user\.rb/
  end
end
