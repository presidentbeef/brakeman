require_relative '../test'

class Rails6Tests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    @@report ||= BrakemanTester.run_scan "rails6", "Rails 6", run_all_checks: true
  end

  def expected
    @@expected ||= {
      :controller => 0,
      :model => 0,
      :template => 4,
      :generic => 3
    }
  end

  def test_sql_injection_delete_by
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "02ad62a4e0cc17d972701be99e1d1ba4761b9176acc36e41498eac3a8d853a8a",
      :warning_type => "SQL Injection",
      :line => 66,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:ivar, :@user), :delete_by, s(:call, s(:params), :[], s(:lit, :user))),
      :user_input => s(:call, s(:params), :[], s(:lit, :user))
  end

  def test_sql_injection_destroy_by
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "5049d89b5d867ce8c2e602746575b512f147b0ff4eca18ac1b2a3a308204180e",
      :warning_type => "SQL Injection",
      :line => 65,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:ivar, :@user), :destroy_by, s(:call, s(:params), :[], s(:lit, :user))),
      :user_input => s(:call, s(:params), :[], s(:lit, :user))
  end

  def test_cross_site_scripting_sanity
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "9e949d88329883f879b7ff46bdb096ba43e791aacb6558f47beddc34b9d42c4c",
      :warning_type => "Cross-Site Scripting",
      :line => 5,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "app/views/users/show.html.erb",
      :code => s(:call, s(:call, s(:const, :User), :new, s(:call, nil, :user_params)), :name),
      :user_input => nil
  end

  def test_cross_site_scripting_2
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "9e949d88329883f879b7ff46bdb096ba43e791aacb6558f47beddc34b9d42c4c",
      :warning_type => "Cross-Site Scripting",
      :line => 6,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "app/views/users/show.html.erb",
      :code => s(:call, s(:call, s(:const, :User), :new, s(:call, nil, :user_params)), :name),
      :user_input => nil
  end

  def test_cross_site_scripting_3
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "9e949d88329883f879b7ff46bdb096ba43e791aacb6558f47beddc34b9d42c4c",
      :warning_type => "Cross-Site Scripting",
      :line => 7,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "app/views/users/show.html.erb",
      :code => s(:call, s(:call, s(:const, :User), :new, s(:call, nil, :user_params)), :name),
      :user_input => nil
  end

  def test_cross_site_scripting_4
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "9e949d88329883f879b7ff46bdb096ba43e791aacb6558f47beddc34b9d42c4c",
      :warning_type => "Cross-Site Scripting",
      :line => 8,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "app/views/users/show.html.erb",
      :code => s(:call, s(:call, s(:const, :User), :new, s(:call, nil, :user_params)), :name),
      :user_input => nil
  end

  def test_remote_code_execution_cookie_serialization
    assert_warning :type => :warning,
      :warning_code => 110,
      :fingerprint => "d882f63ce96c28fb6c6e0982f2a171460e4b933bfd9b9a5421dca21eef3f76da",
      :warning_type => "Remote Code Execution",
      :line => 5,
      :message => /^Use\ of\ unsafe\ cookie\ serialization\ strat/,
      :confidence => 1,
      :relative_path => "config/initializers/cookies_serializer.rb",
      :code => s(:attrasgn, s(:call, s(:call, s(:call, s(:const, :Rails), :application), :config), :action_dispatch), :cookies_serializer=, s(:lit, :marshal)),
      :user_input => nil
  end
end
