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
      :generic => 17
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

  def test_sql_injection_strip_heredoc
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "c567289064ac39d277b33a5b860641b79a8139cf85a9a079bc7bb36130784a93",
      :warning_type => "SQL Injection",
      :line => 11,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/user.rb",
      :code => s(:call, nil, :where, s(:call, s(:dstr, "      name = '", s(:evstr, s(:lvar, :name)), s(:str, "'\n")), :strip_heredoc)),
      :user_input => s(:lvar, :name)
  end

  def test_sql_injection_squish_string
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "061b514e5a37df58d8b64ec0c9c10002dcd9d7253d0e1c1a9bd61bdb27be158f",
      :warning_type => "SQL Injection",
      :line => 15,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:call, s(:colon2, s(:const, :ActiveRecord), :Base), :connection), :execute, s(:call, s(:dstr, "SELECT * FROM ", s(:evstr, s(:call, nil, :user_input))), :squish)),
      :user_input => s(:call, nil, :user_input)
  end

  def test_sql_injection_strip_string
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "07fe35888f23cd4125c862d041b9ab3257c01c1263b66cd8c63804d55b8e1549",
      :warning_type => "SQL Injection",
      :line => 16,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:call, s(:colon2, s(:const, :ActiveRecord), :Base), :connection), :execute, s(:call, s(:dstr, "SELECT * FROM ", s(:evstr, s(:call, nil, :user_input))), :strip)),
      :user_input => s(:call, nil, :user_input)
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

  def test_cross_site_scripting_json_escape_config
    assert_warning :type => :warning,
      :warning_code => 113,
      :fingerprint => "fea6a166c0704d9525d109c17d6ee95eda217dfb1ef56a4d4c91ec9bd384cbf8",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^HTML\ entities\ in\ JSON\ are\ not\ escaped\ by/,
      :confidence => 1,
      :relative_path => "config/environments/production.rb",
      :code => nil,
      :user_input => nil
  end

  def test_cross_site_scripting_json_escape_module
    assert_warning :type => :warning,
      :warning_code => 114,
      :fingerprint => "8275f584e7cced41c26890e574cdbf6804bddff54374058834a562294c99d6f6",
      :warning_type => "Cross-Site Scripting",
      :line => 2,
      :message => /^HTML\ entities\ in\ JSON\ are\ not\ escaped\ by/,
      :confidence => 1,
      :relative_path => "config/environments/production.rb",
      :code => s(:attrasgn, s(:colon2, s(:colon2, s(:const, :ActiveSupport), :JSON), :Encoding), :escape_html_entities_in_json=, s(:false)),
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

  def test_dup_call
    assert_no_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "5c2a887ac2e7ba5ae8d27160c0b4540d9ddb93ae8cde64f84558544e2235c83e",
      :warning_type => "Redirect",
      :line => 6,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, nil, :redirect_to, s(:call, s(:call, s(:const, :Group), :find, s(:call, s(:params), :[], s(:lit, :id))), :dup)),
      :user_input => s(:call, s(:call, s(:const, :Group), :find, s(:call, s(:params), :[], s(:lit, :id))), :dup)
  end

  def test_redirect_request_params
    assert_warning :type => :warning,
      :warning_code => 18,
      :fingerprint => "1d18e872e5f74ff0fd445008fd00ea2f04d5b3086f18682e301621779cd609a2",
      :warning_type => "Redirect",
      :line => 88,
      :message => /^Possible\ unprotected\ redirect/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, nil, :redirect_to, s(:call, s(:call, nil, :request), :params)),
      :user_input => s(:call, s(:call, nil, :request), :params)
  end

  def test_basic_dash_c_command_injection
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "22f0226c43eeb59bff49e4f0ea10014c2882c8be2f51e4d36876a26960b100d9",
      :warning_type => "Command Injection",
      :line => 70,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, nil, :system, s(:str, "bash"), s(:str, "-c"), s(:call, s(:params), :[], s(:lit, :script))),
      :user_input => s(:call, s(:params), :[], s(:lit, :script))
  end

  def test_complex_dash_c_command_injection
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "d5b5eeed916c878c897bcde8b922bb18cdcf9fc1acfb8e37b30eb02422e8c43e",
      :warning_type => "Command Injection",
      :line => 75,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, nil, :exec, s(:str, "zsh"), s(:str, "-c"), s(:dstr, "", s(:evstr, s(:call, s(:params), :[], s(:lit, :script))), s(:str, " -e ./"))),
      :user_input => s(:call, s(:params), :[], s(:lit, :script))
  end

  def test_without_shell_dash_c_is_not_command_injection
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :warning_type => "Command Injection",
      :line => 84,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, nil, :system, s(:str, "bash"), s(:str, "-c"), s(:call, s(:params), :[], s(:lit, :argument))),
      :user_input => s(:call, s(:params), :[], s(:lit, :argument))
  end

  def test_command_injection_in_render_1
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "6c1c068078e37b94af882d43bd6e239dd8e28912b7f0a56f11b82a504915c064",
      :warning_type => "Command Injection",
      :line => 10,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:dxstr, "", s(:evstr, s(:call, s(:params), :require, s(:str, "name"))), s(:str, " some optional text")),
      :user_input => s(:call, s(:params), :require, s(:str, "name"))
  end

  def test_command_injection_in_render_2
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "6c1c068078e37b94af882d43bd6e239dd8e28912b7f0a56f11b82a504915c064",
      :warning_type => "Command Injection",
      :line => 11,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:dxstr, "", s(:evstr, s(:call, s(:params), :require, s(:str, "name"))), s(:str, " some optional text")),
      :user_input => s(:call, s(:params), :require, s(:str, "name"))
  end

  def test_mass_assignment_permit_bang_1
    assert_warning :type => :warning,
      :warning_code => 70,
      :fingerprint => "58e42d4ef79c278374a8456b1c034c7768e28b9a156e5602bb99a1105349f350",
      :warning_type => "Mass Assignment",
      :line => 93,
      :message => /^Parameters\ should\ be\ whitelisted\ for\ mas/,
      :confidence => 1,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:params), :permit!),
      :user_input => nil
  end

  def test_mass_assignment_permit_bang_2
    assert_warning :type => :warning,
      :warning_code => 70,
      :fingerprint => "58e42d4ef79c278374a8456b1c034c7768e28b9a156e5602bb99a1105349f350",
      :warning_type => "Mass Assignment",
      :line => 94,
      :message => /^Parameters\ should\ be\ whitelisted\ for\ mas/,
      :confidence => 1,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:params), :permit!),
      :user_input => nil
  end

  def test_mass_assignment_global_allow_all_parameters
    assert_warning :type => :warning,
      :warning_code => 112,
      :fingerprint => "a02bb53bb433ffd7e52cfd58f9a3fdf20f53d082db36d2e47bf3c0aee32458ae",
      :warning_type => "Mass Assignment",
      :line => 2,
      :message => /^Parameters\ should\ be\ whitelisted\ for\ mas/,
      :confidence => 0,
      :relative_path => "config/initializers/allow_all_parameters.rb",
      :code => s(:attrasgn, s(:colon2, s(:const, :ActionController), :Parameters), :permit_all_parameters=, s(:true)),
      :user_input => nil
  end

  def test_secrets_file_1
    assert_warning :type => :warning,
      :warning_code => 101,
      :fingerprint => "6036cfd256d955c52298c798e37b363f923d9c38f0a77599bfae942839a1dc4e",
      :warning_type => "Authentication",
      :line => 3,
      :message => /^Hardcoded\ value\ for\ `DEFAULT_PASSWORD`\ i/,
      :confidence => 1,
      :relative_path => "app/models/user.rb",
      :code => nil,
      :user_input => nil
  end
end
