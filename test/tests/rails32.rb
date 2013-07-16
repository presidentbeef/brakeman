abort "Please run using test/test.rb" unless defined? BrakemanTester

Rails32 = BrakemanTester.run_scan "rails3.2", "Rails 3.2"

class Rails32Tests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def expected
    @expected ||= {
      :controller => 0,
      :model => 5,
      :template => 11,
      :generic => 7 }


    if RUBY_PLATFORM == 'java'
      @expected[:generic] += 1
    end

    @expected
  end

  def report
    Rails32
  end

  def test_rc_version_number
    assert_equal "3.2.9.rc2", Rails32[:config][:rails_version]
  end

  def test_sql_injection_CVE_2012_5664
    assert_warning :type => :warning,
      :warning_type => "SQL Injection",
      :message => /CVE-2012-5664/,
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

  def test_remote_code_execution_CVE_2013_0156
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ a\ remote\ code\ execut/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_remote_code_execution_CVE_2013_0269
    assert_warning :type => :warning,
      :warning_type => "Remote Code Execution",
      :message => /^json\ gem\ version\ 1\.7\.5\ has\ a\ remote\ code/,
      :confidence => 0,
      :file => /Gemfile/
  end

  def test_xss_sanitize_css_CVE_2013_1855
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 2,
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ a\ vulnerability\ in\ s/,
      :confidence => 0,
      :file => /sanitized\.html\.erb/
  end

  def test_xml_jruby_parsing_CVE_2013_1856
    if RUBY_PLATFORM == 'java'
      assert_warning :type => :warning,
        :warning_type => "File Access",
        :message => /^Rails\ 3\.2\.9\.rc2 with\ JRuby\ has\ a\ vulnerabili/,
        :confidence => 0,
        :file => /Gemfile/
    end
  end

  def test_denial_of_service_CVE_2013_1854
    assert_warning :type => :warning,
      :warning_type => "Denial of Service",
      :message => /^Rails\ 3\.2\.9\.rc2\ has\ a\ denial\ of\ service\ vul/,
      :confidence => 1,
      :file => /Gemfile/
  end

  def test_redirect_1
    assert_warning :type => :warning,
      :warning_type => "Redirect",
      :line => 14,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :file => /removal_controller\.rb/
  end

  def test_cross_site_scripting_2
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /_partial\.html\.erb/
  end

  def test_cross_site_scripting_3
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /controller_removed\.html\.erb/
  end

  def test_cross_site_scripting_4
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 2,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /implicit_render\.html\.erb/
  end

  def test_cross_site_scripting_5
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /_form\.html\.erb/
  end

  def test_cross_site_scripting_6
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 1,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /mixed_in\.html\.erb/
  end

  def test_cross_site_scripting_7
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 15,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /show\.html\.erb/
  end

  def test_escaped_params_to_json
    assert_no_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 21,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /show\.html\.erb/
  end

  def test_cross_site_scripting_in_slim_param
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 3,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /slimming\.html\.slim/
  end

  def test_cross_site_scripting_in_slim_model
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 4,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /slimming\.html\.slim/
  end

  def test_cross_site_scripting_slim_partial_param
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 6,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :file => /_slimmer\.html\.slim/
  end

  def test_cross_site_scripting_slim_partial_model
    assert_warning :type => :template,
      :warning_type => "Cross Site Scripting",
      :line => 8,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :file => /_slimmer\.html\.slim/
  end

  def test_mass_assignment_default
    assert_no_warning :type => :model,
      :warning_type => "Attribute Restriction",
      :message => /^Mass\ assignment\ is\ not\ restricted\ using\ /,
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

  def test_model_attr_accessible_admin
    assert_warning :type => :model,
      :warning_type => "Mass Assignment",
      :message => /^Potentially\ dangerous\ attribute\ admin/,
      :confidence => 0, #HIGH
      :file => /user\.rb/
  end 

  def test_model_attr_accessible_account_id
    assert_warning :type => :model,
      :warning_type => "Mass Assignment",
      :message => /^Potentially\ dangerous\ attribute\ account_id/,
      :confidence => 0, 
      :file => /user\.rb/
  end 

  def test_model_attr_accessible_account_banned
    assert_warning :type => :model,
      :warning_type => "Mass Assignment",
      :message => /^Potentially\ dangerous\ attribute\ banned/,
      :confidence => 1, #MED
      :file => /account\.rb/
  end 

  def test_model_attr_accessible_status_id
    assert_warning :type => :model,
      :warning_type => "Mass Assignment",
      :message => /^Potentially\ dangerous\ attribute\ status_id/,
      :confidence => 2, #LOW
      :file => /user\.rb/
  end 

  def test_model_attr_accessible_plan_id
    assert_warning :type => :model,
      :warning_type => "Mass Assignment",
      :message => /^Potentially\ dangerous\ attribute\ plan_id/,
      :confidence => 2, 
      :file => /account\.rb/
  end 

end
