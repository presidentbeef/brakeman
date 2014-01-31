abort "Please run using test/test.rb" unless defined? BrakemanTester

RailsWithXssPlugin = BrakemanTester.run_scan "rails_with_xss_plugin", "RailsWithXssPlugin", :absolute_paths => true

class RailsWithXssPluginTests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def expected
    @expected ||= {
      :controller => 1,
      :model => 3,
      :template => 2,
      :generic => 23 }
  end

  def report
    RailsWithXssPlugin
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
      :warning_type => "Cross Site Scripting",
      #noline,
      :message => /^Rails\ 2\.3\.x\ using\ the\ rails_xss\ plugin\ h/,
      :confidence => 1,
      :file => /Gemfile/
  end


  def test_cross_site_scripting_14 
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 13,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /show\.html\.erb/
  end

  def test_cross_site_scripting_single_quotes_CVE_2012_3464
    assert_no_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
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
      :fingerprint => "e725c387439202f28c1983bf225323d93b5891695c91b9389740e2da3d74855e",
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
      :message => /^'protect_from_forgery'\ should\ be\ called\ /,
      :confidence => 0,
      :file => /application_controller\.rb/
  end


  def test_attribute_restriction_19 
    assert_warning :type => :model,
      :warning_type => "Attribute Restriction",
      #noline,
      :message => /^Mass\ assignment\ is\ not\ restricted\ using\ /,
      :confidence => 0,
      :file => /post,\ user\.rb/
  end


  def test_format_validation_20 
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 5,
      :message => /^Insufficient\ validation\ for\ 'user_name'\ /,
      :confidence => 0,
      :file => /user\.rb/
  end


  def test_format_validation_21 
    assert_warning :type => :model,
      :warning_type => "Format Validation",
      :line => 7,
      :message => /^Insufficient\ validation\ for\ 'display_nam/,
      :confidence => 0,
      :file => /user\.rb/
  end

  def test_strip_tags_CVE_2012_3465
    assert_warning :type => :warning,
      :warning_type => "Cross Site Scripting",
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
      :warning_type => "Cross Site Scripting",
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
    assert report[:generic_warnings].all? { |w| w.file.start_with? "/" }
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
      :message => /^json\ gem\ version\ 1\.1\.0\ has\ a\ symbol\ crea/,
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
      :line => nil,
      :message => /^Rails\ 2\.3\.14\ contains\ a\ SQL\ injection\ vu/,
      :confidence => 0,
      :relative_path => "Gemfile",
      :user_input => nil
  end

  def test_number_to_currency_CVE_2013_6415
    assert_warning :type => :warning,
      :warning_code => 65,
      :fingerprint => "813b00b5c58567fb3f32051578b839cb25fc2d827834a30d4b213a4c126202a2",
      :warning_type => "Cross Site Scripting",
      :line => nil,
      :message => /^Rails\ 2\.3\.14\ has\ a\ vulnerability\ in\ numb/,
      :confidence => 1,
      :relative_path => "Gemfile",
      :user_input => nil
  end
end
