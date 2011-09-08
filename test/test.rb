$:.unshift "#{File.expand_path(File.dirname(__FILE__))}/../lib"

require 'set'

OPTIONS = { :skip_checks => Set.new, 
  :check_arguments => true, 
  :safe_methods => Set.new,
  :min_confidence => 2,
  :combine_locations => true,
  :collapse_mass_assignment => true,
  :ignore_redirect_to_model => true,
  :ignore_model_output => false }

require 'scanner'

$stderr.puts "-" * 40
$stderr.puts "Processing Rails 2 application..."
$stderr.puts "-" * 40
OPTIONS[:app_path] = File.expand_path "./rails2"
scan2 = Scanner.new("rails2").process
scan2.run_checks
Rails2 = Report.new(scan2).to_test

$stderr.puts "-" * 40
$stderr.puts "Processing Rails 3 application..."
$stderr.puts "-" * 40
OPTIONS[:app_path] = File.expand_path "./rails3"
OPTIONS[:rails3] = true
load 'processors/route_processor.rb'
scan3 = Scanner.new("rails3").process
scan3.run_checks
Rails3 = Report.new(scan3).to_test

$stderr.puts "-" * 40
$stderr.puts "Processing Rails 3.1 application..."
$stderr.puts "-" * 40
OPTIONS[:app_path] = File.expand_path "./rails3.1"
OPTIONS[:rails3] = true
load 'processors/route_processor.rb'
scan31 = Scanner.new("rails3.1").process
scan31.run_checks
Rails31 = Report.new(scan31).to_test

$stderr.puts "-" * 40
$stderr.puts "Checking results..."
$stderr.puts "-" * 40
require 'test/unit'

module FindWarning
  def assert_warning opts
    warnings = find opts
    assert_not_equal 0, warnings.length, "No warning found"
    assert_equal 1, warnings.length, "Matched more than one warning"
  end 

  def find opts = {}, &block
    t = opts[:type]
    if t.nil? or t == :warning
      warnings = report[:warnings]
    else
      warnings = report[(t.to_s << "_warnings").to_sym]
    end

    opts.delete :type

    result = if block
      warnings.select block
    else
      warnings.select do |w|
        flag = true
        opts.each do |k,v|
          unless v === w.send(k)
            flag = false
            break
          end
        end
        flag
      end
    end

    warnings.reject! {|w| result.include? w }

    if result.length > 0 and warnings.length == 0
      puts "Good, all #{t} warnings matched."
    end

    result
  end
end

class Rails2Tests < Test::Unit::TestCase
  include FindWarning

  def report
    Rails2
  end

  def test_no_errors
    assert_equal 0, report[:errors].length
  end

  def test_eval
    assert_warning :warning_type => "Dangerous Eval",
      :line => 41,
      :message => /^User input in eval/,
      :code => /eval\(params\[:dangerous_input\]\)/,
      :file => /home_controller.rb/
  end

  def test_default_routes
    assert_warning :warning_type => "Default Routes",
      :line => 41,
      :message => /All public methods in controllers are available as actions/,
      :file => /routes\.rb/
  end

  def test_command_injection_interpolate
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 34,
      :message => /^Possible command injection/,
      :confidence => 1,
      :file => /home_controller\.rb/
  end

  def test_command_injection_direct
    assert_warning :type => :warning,
      :warning_type => "Command Injection",
      :line => 37,
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

  def test_redirect
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 46,
      :message => /^Possible unprotected redirect/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_dynamic_render_path
    assert_warning :type => :warning,
      :warning_type => "Dynamic Render Path",
      :line => 60,
      :message => /^Render path is dynamic/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_file_access
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 22,
      :message => /^Parameter value used in file name/,
      :confidence => 0,
      :file => /other_controller\.rb/
  end

  def test_file_access_with_load
    assert_warning :type => :warning,
      :warning_type => "File Access",
      :line => 64,
      :message => /^Parameter value used in file name/,
      :confidence => 0,
      :file => /home_controller\.rb/
  end

  def test_file_access_load_false
    warnings = find :type => :warning,
      :warning_type => "File Access",
      :line => 65,
      :message => /^Parameter value used in file name/,
      :confidence => 0,
      :file => /home_controller\.rb/

    assert_equal 0, warnings.length, "False positive found."
  end

  def test_session_secret
    assert_warning :type => :warning,
      :warning_type => "Session Setting",
      :line => 9,
      :message => /^Session secret should be at least 30 cha/,
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

  def test_params_from_controller
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
    assert_warning :type => :template,
      :warning_type => "SQL Injection",
      :line => 4,
      :message => /^Possible SQL injection/,
      :confidence => 0,
      :file => /test_sql\.html\.erb/
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

end

class Rails3Tests < Test::Unit::TestCase
  include FindWarning
  
  def report
    Rails3
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
      :confidence => 1,
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
      :confidence => 1,
      :file => /home_controller\.rb/
  end
end

class Rails31Tests < Test::Unit::TestCase
  include FindWarning
  
  def report
    Rails31
  end

  def test_without_protection
    assert_warning :type => :warning,
      :warning_type => "Mass Assignment",
      :line => 47,
      :message => /^Unprotected mass assignment/,
      :confidence => 0,
      :file => /users_controller\.rb/ 
  end

  def test_unprotected_redirect
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 67,
      :message => /^Possible unprotected redirect/,
      :confidence => 2,
      :file => /users_controller\.rb/ 
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
end

class BrakemanTests < Test::Unit::TestCase
  def util
    Class.new.extend Util
  end

  def test_cookies?
    assert util.cookies?(RubyParser.new.parse 'cookies[:x][:y][:z]')
  end

  def test_params?
    assert util.params?(RubyParser.new.parse 'params[:x][:y][:z]')
  end
end
