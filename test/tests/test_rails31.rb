abort "Please run using test/test.rb" unless defined? BrakemanTester

Rails31 = BrakemanTester.run_scan "rails3.1", "Rails 3.1", :rails3 => true

class Rails31Tests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    Rails31
  end

  def expected
    @expected ||= {
      :model => 0,
      :template => 4,
      :controller => 1,
      :warning => 44 }
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
      :line => 6,
      :message => /^Basic authentication password stored in source code/,
      :confidence => 0,
      :file => /users_controller\.rb/
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

  def test_sql_injection_in_order_param
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
      :line => 93,
      :message => /^Use\ whitelist\ \(:only\ =>\ \[\.\.\]\)\ when\ skipp/,
      :confidence => 1,
      :file => /users_controller\.rb/
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
      :message => /^User\ input\ value\ used\ in\ file\ name/,
      :confidence => 1,
      :file => /users_controller\.rb/
  end
end
