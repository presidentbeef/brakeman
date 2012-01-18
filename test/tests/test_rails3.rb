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
      :model => 4,
      :template => 18,
      :warning => 18
    }
  end

  def test_no_errors
    assert_equal 0, report[:errors].length
  end

  def test_eval_params
    assert_warning :type => :warning,
      :warning_type => "Dangerous Eval",
      :line => 41,
      :message => /^User input in eval near line 41: eval\(pa/,
      :confidence => 0,
      :file => /home_controller\.rb/
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
      :line => 37,
      :message => /^Possible command injection near line 37:/,
      :confidence => 0,
      :file => /home_controller\.rb/
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
      :line => 68,
      :message => /^Parameter value used in file name near l/,
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

  def test_redirect
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 46,
      :message => /^Possible unprotected redirect near line /,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_render_path
    assert_warning :type => :warning,
      :warning_type => "Dynamic Render Path",
      :line => 64,
      :message => /^Render path is dynamic near line 64: ren/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_file_access_send_file
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 22,
      :message => /^Parameter value used in file name near l/,
      :confidence => 0,
      :file => /other_controller\.rb/
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
      :message => /^Unescaped model attribute near line 1: \(/,
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
    assert_warning :type => :template,
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
      :line => 93,
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

  def test_translate_bug
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
      :message => /^Versions before 3.0.11 have a vulnerability/,
      :confidence => 1,
      :file => /Gemfile/
  end
end

