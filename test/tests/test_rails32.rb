abort "Please run using test/test.rb" unless defined? BrakemanTester

Rails32 = BrakemanTester.run_scan "rails3.2", "Rails 3.2"

class Rails32Tests < Test::Unit::TestCase
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def expected
    @expected ||= {
      :controller => 0,
      :model => 0,
      :template => 6,
      :warning => 2 }
  end

  def report
    Rails32
  end

  def test_rc_version_number
    assert_equal "3.2.9.rc2", Rails32[:config][:rails_version]
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
end
