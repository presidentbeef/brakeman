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

OPTIONS[:app_path] = File.expand_path "./rails2"
scan2 = Scanner.new("rails2").process
scan2.run_checks
Rails2 = Report.new(scan2).to_test

OPTIONS[:app_path] = File.expand_path "./rails3"
OPTIONS[:rails3] = true
scan3 = Scanner.new("rails3").process
scan3.run_checks
Rails3 = Report.new(scan3).to_test

=begin
[:warnings, :controller_warnings, :model_warnings, :template_warnings].each do |meth|
  Rails2[meth].each do |w|
    puts <<-THING
  def test_
    assert_warning :type => #{meth.to_s.gsub(/_warnings|s$/,"").inspect},
      :warning_type => #{w.warning_type.inspect},
      :line => #{w.line},
      :message => /^#{w.message[0,40]}/,
      :confidence => #{w.confidence},
      :file => /#{File.basename(w.file || "").gsub(/\./, "\\.")}/
  end

    THING
  end
end
=end

require 'test/unit'

module FindWarning
  def assert_warning opts
    warnings = find opts
    assert_not_equal 0, warnings.length, "No warning found"
    assert_equal 1, warnings.length, "Matched more than one warning"
  end 

 def find opts = {}, &block
    if opts[:type].nil? or opts[:type] == :warning
      warnings = report[:warnings]
    else
      warnings = report[(opts[:type].to_s << "_warnings").to_sym]
    end

    opts.delete :type

    if block
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

  def test_index_output
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped parameter value/,
      :confidence => 0,
      :file => /home\/index.html/
  end

  def test_command_injection
    assert_warning :warning_type => "Command Injection",
      :line => 37,
      :message => /^Possible command injection/,
      :code => /params\[:user_input\]/,
      :file => /home_controller.rb/
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

end

class Rails3Tests < Test::Unit::TestCase
  include FindWarning
  
  def report
    Rails3
  end

  def test_no_errors
    assert_equal 0, report[:errors].length
  end
end
