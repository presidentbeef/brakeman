require_relative '../test'

class Rails6Tests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    @@report ||= BrakemanTester.run_scan "rails6", "Rails 6", :run_all_checks => true, :sql_safe_methods => [:sanitize_s]
  end

  def expected
    @@expected ||= {
      :controller => 0,
      :model => 0,
      :template => 4,
      :generic => 37
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
      :line => 19,
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
      :line => 20,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:call, s(:colon2, s(:const, :ActiveRecord), :Base), :connection), :execute, s(:call, s(:dstr, "SELECT * FROM ", s(:evstr, s(:call, nil, :user_input))), :strip)),
      :user_input => s(:call, nil, :user_input)
  end

  def test_sql_injection_chomp_string
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "e5f6e40868c9046e5c1433e4975e49b65967de1dcf3add7ba35248b897eeea1c",
      :warning_type => "SQL Injection",
      :line => 20,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/user.rb",
      :code => s(:call, s(:call, s(:colon2, s(:const, :ActiveRecord), :Base), :connection), :delete, s(:call, s(:dstr, "DELETE FROM ", s(:evstr, s(:call, nil, :table)), s(:str, " WHERE updated_at < now() - interval '"), s(:evstr, s(:call, nil, :period)), s(:str, "'\n")), :chomp)),
      :user_input => s(:call, nil, :table)
  end

  def test_sql_injection_nonstandard_directory
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "633da061d9412e2a270133526a45933e29553846c677254abfd0d0955e69f064",
      :warning_type => "SQL Injection",
      :line => 3,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/widgets/widget.rb",
      :code => s(:call, nil, :where, s(:dstr, "direction = ", s(:evstr, s(:lvar, :direction)), s(:str, ")"))),
      :user_input => s(:lvar, :direction)
  end

  def test_sql_injection_uuid_false_positive
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "8ebbafd2b7d6aa2d6ab639c6678ae1f5489dc3166747bbad8919e95156592321",
      :warning_type => "SQL Injection",
      :line => 3,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/models/group.rb",
      :code => s(:call, s(:call, s(:colon2, s(:const, :ActiveRecord), :Base), :connection), :exec_query, s(:dstr, "select * where x = ", s(:evstr, s(:call, s(:const, :User), :uuid)))),
      :user_input => s(:call, s(:const, :User), :uuid)
  end

  def test_sql_injection_safe_sql_methods_false_postitive
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "205c9aaba1e719acc4f7026c0f65f172d4ac8dd8d036d31a94d7d446c7c874e7",
      :warning_type => "SQL Injection",
      :line => 60,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:call, s(:colon2, s(:const, :ActiveRecord), :Base), :connection), :execute, s(:dstr, "SELECT * FROM ", s(:evstr, s(:call, nil, :sanitize_s, s(:call, nil, :user_input))))),
      :user_input => s(:call, nil, :sanitize_s, s(:call, nil, :user_input))
  end

  def test_sql_injection_date_integer_target_false_positive
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "5ec829ba8790c01a39faf6788f0754d39879a6e68a9de8804c6f25ac9c2f1ee6",
      :warning_type => "SQL Injection",
      :line => 8,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/group.rb",
      :code => s(:call, s(:const, :Arel), :sql, s(:dstr, "created_at > '", s(:evstr, s(:call, s(:call, s(:lit, 30), :days), :ago)), s(:str, "'"))),
      :user_input => s(:call, s(:call, s(:lit, 30), :days), :ago)
  end

  def test_sql_injection_sanitize_sql_like
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "8dde11c95a0f3acb4f982ff6554ac3ba821334ee04aee7f1fb0ea01c8919baad",
      :warning_type => "SQL Injection",
      :line => 13,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/group.rb",
      :code => s(:call, s(:const, :Arel), :sql, s(:dstr, "name ILIKE '%", s(:evstr, s(:call, s(:colon2, s(:const, :ActiveRecord), :Base), :sanitize_sql_like, s(:lvar, :query))), s(:str, "%'"))),
      :user_input => s(:call, s(:colon2, s(:const, :ActiveRecord), :Base), :sanitize_sql_like, s(:lvar, :query))
  end

  def test_sql_injection_hash_fetch_all_literals
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "1b9a04c9fdc4b8c7f215387fb726dc542c2d35dde2f29b48a76248443524a5fa",
      :warning_type => "SQL Injection",
      :line => 14,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/group.rb",
      :code => s(:call, s(:const, :Arel), :sql, s(:dstr, "role = '", s(:evstr, s(:call, s(:hash, s(:lit, :admin), s(:lit, 1), s(:lit, :moderator), s(:lit, 2)), :fetch, s(:lvar, :role_name))), s(:str, "'"))),
      :user_input => s(:call, s(:hash, s(:lit, :admin), s(:lit, 1), s(:lit, :moderator), s(:lit, 2)), :fetch, s(:lvar, :role_name))
  end

  def test_sql_injection_with_date
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "d8eec07773f66d6818a9dab2533bda5b295fbe261de5df9675dbf3213c1dcfa2",
      :warning_type => "SQL Injection",
      :line => 25,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/user.rb",
      :code => s(:call, nil, :where, s(:dstr, "date > ", s(:evstr, s(:call, s(:call, s(:const, :Date), :today), :-, s(:lit, 1))))),
      :user_input => s(:call, s(:call, s(:const, :Date), :today), :-, s(:lit, 1))
  end

  def test_sql_injection_rewhere
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "7f5154ba5124c5ae26ec23f364239311df959acb9b2e4d09f4867c2fbd954dd6",
      :warning_type => "SQL Injection",
      :line => 69,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:call, s(:const, :User), :where, s(:str, "x = 1")), :rewhere, s(:dstr, "x = ", s(:evstr, s(:call, s(:params), :[], s(:lit, :x))))),
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_sql_injection_reselect
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "e4fdd9614cff8e8f8a70cd983c55d36acd6da219048faf1530de9dc43d58aa71",
      :warning_type => "SQL Injection",
      :line => 68,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:call, s(:const, :User), :select, s(:str, "stuff")), :reselect, s(:call, s(:params), :[], s(:lit, :columns))),
      :user_input => s(:call, s(:params), :[], s(:lit, :columns))
  end

  def test_sql_injection_pluck
    # Not in Rails 6.1 though
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "69a7e516b2b409dc8d74f6a26b44d62f4b842ce9c73e96c3910f9206c6fc50f5",
      :warning_type => "SQL Injection",
      :line => 70,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:const, :User), :pluck, s(:call, s(:params), :[], s(:lit, :column))),
      :user_input => s(:call, s(:params), :[], s(:lit, :column))
  end

  def test_sql_injection_order
    # Not in Rails 6.1 though
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "47e9c6316ae9b2937121298ebc095bac4c4c8682779a0be95ce32c3fc4ba3118",
      :warning_type => "SQL Injection",
      :line => 71,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:const, :User), :order, s(:dstr, "name ", s(:evstr, s(:call, s(:params), :[], s(:lit, :direction))))),
      :user_input => s(:call, s(:params), :[], s(:lit, :direction))
  end

  def test_sql_injection_reorder
    # Not in Rails 6.1 though
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "c6b303b67a5de261d9faaa84e02b29987b57fb443691d7ad77956bbecf41a1d0",
      :warning_type => "SQL Injection",
      :line => 72,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:call, s(:const, :User), :order, s(:lit, :name)), :reorder, s(:call, s(:params), :[], s(:lit, :column))),
      :user_input => s(:call, s(:params), :[], s(:lit, :column))
  end

  def test_sql_injection_enum
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "b2071137eba7ef6ecbcc1c6381a428e5c576a5fadf73dc04b2e155c41043e1d2",
      :warning_type => "SQL Injection",
      :line => 31,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/models/user.rb",
      :code => s(:call, nil, :where, s(:dstr, "state = ", s(:evstr, s(:call, s(:call, s(:const, :User), :states), :[], s(:str, "pending"))))),
      :user_input => s(:call, s(:call, s(:const, :User), :states), :[], s(:str, "pending"))
  end

  def test_sql_injection_locale
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "843143d5a9dcfa097c66d80a6a72ba151c0332f1ea8c8bc852e418d4f0e2cb7b",
      :warning_type => "SQL Injection",
      :line => 37,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/user.rb",
      :code => s(:call, s(:const, :User), :where, s(:dstr, "lower(slug_", s(:evstr, s(:call, s(:call, s(:call, s(:call, s(:const, :I18n), :locale), :to_s), :split, s(:str, "-")), :first)), s(:str, ") = :country_id")), s(:hash, s(:lit, :country_id), s(:call, s(:params), :[], s(:lit, :new_country_id)))),
      :user_input => s(:call, s(:call, s(:call, s(:call, s(:const, :I18n), :locale), :to_s), :split, s(:str, "-")), :first)
  end

  def test_sql_injection_tr_method
    assert_warning check_name: "SQL",
      type: :warning,
      warning_code: 0,
      fingerprint: "5d5e33e109c52601027f20eb706d6f7688dffaaebc3b62e92a57bb74f7dab451",
      warning_type: "SQL Injection",
      line: 37,
      message: /^Possible\ SQL\ injection/,
      confidence: 1,
      relative_path: "app/controllers/accounts_controller.rb",
      code: s(:call, s(:const, :Arel), :sql, s(:call, s(:dstr, "CASE\nWHEN ", s(:evstr, s(:call, s(:call, nil, :user_params), :[], s(:lit, :field))), s(:str, " IS NULL\n  OR TRIM("), s(:evstr, s(:call, s(:call, nil, :user_params), :[], s(:lit, :field))), s(:str, ") = ''\nTHEN 'Untitled'\nELSE TRIM("), s(:evstr, s(:call, s(:call, nil, :user_params), :[], s(:lit, :field))), s(:str, ")\nEND\n")), :tr, s(:str, "\n"), s(:str, " "))),
      user_input: s(:call, s(:call, nil, :user_params), :[], s(:lit, :field))
  end

  def test_dangerous_send_enum
    assert_no_warning :type => :warning,
      :warning_code => 23,
      :fingerprint => "483fa36e41f5791e86f345a19b517a61859886d685ce40ef852871bb7a935f2d",
      :warning_type => "Dangerous Send",
      :line => 80,
      :message => /^User\ controlled\ method\ execution/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:const, :Group), :send, s(:call, s(:dstr, "", s(:evstr, s(:call, s(:params), :[], s(:lit, :status)))), :to_sym)),
      :user_input => s(:call, s(:params), :[], s(:lit, :status))
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

  def test_remote_code_execution_method
    assert_warning :type => :warning,
      :warning_code => 119,
      :fingerprint => "f4c435cdf78761be48879a05c84db905558d192cb6693640174ff3c0f18b61cd",
      :warning_type => "Remote Code Execution",
      :line => 48,
      :message => /^Unsafe\ reflection\ method\ `method`\ called/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:call, s(:call, s(:params), :[], s(:lit, :klass)), :to_s), :method, s(:call, s(:params), :[], s(:lit, :method))),
      :user_input => s(:call, s(:params), :[], s(:lit, :method))
  end

  def test_remote_code_execution_tap
    assert_warning :type => :warning,
      :warning_code => 119,
      :fingerprint => "988c82365b897a118c1c2b49059dc2b7202333ecc8bdd3a182ae0c126db2fca4",
      :warning_type => "Remote Code Execution",
      :line => 49,
      :message => /^Unsafe\ reflection\ method\ `tap`\ called\ wi/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:const, :Kernel), :tap, s(:block_pass, s(:call, s(:call, s(:params), :[], s(:lit, :method)), :to_sym))),
      :user_input => s(:call, s(:call, s(:params), :[], s(:lit, :method)), :to_sym)
  end

  def test_remote_code_execution_to_proc
    assert_warning :type => :warning,
      :warning_code => 119,
      :fingerprint => "0eceb89cbf8d71f0aa8ada268bb0042f6efefee746e015adaa656d33e87c2f6e",
      :warning_type => "Remote Code Execution",
      :line => 47,
      :message => /^Unsafe\ reflection\ method\ `to_proc`\ calle/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:call, s(:call, s(:params), :[], s(:lit, :method)), :to_sym), :to_proc),
      :user_input => s(:call, s(:call, s(:params), :[], s(:lit, :method)), :to_sym)
  end

  def test_remote_code_execution_not_query_parameters
    assert_warning :type => :warning,
      :warning_code => 119,
      :fingerprint => "78e2d9010374d26ef8fe31ed22f10a6de7dfc428e0387dd8502cd5833ffe4aa6",
      :warning_type => "Remote Code Execution",
      :line => 50,
      :message => /^Unsafe\ reflection\ method\ `method`\ called/,
      :confidence => 1,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:const, :User), :method, s(:dstr, "", s(:evstr, s(:call, s(:call, s(:const, :User), :first), :some_method_thing)), s(:str, "_stuff"))),
      :user_input => s(:call, s(:call, s(:const, :User), :first), :some_method_thing)
  end

  def test_safe_yaml_load_option
    assert_no_warning :type => :warning,
      :warning_code => 25,
      :fingerprint => "bf38405dcc489a459957bf515cb9f078686bb9316cc3d1f421c61c330a9005ec",
      :warning_type => "Remote Code Execution",
      :line => 41,
      :message => /^`YAML\.load`\ called\ with\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:const, :YAML), :load, s(:call, s(:params), :[], s(:lit, :yaml_stuff)), s(:hash, s(:lit, :safe), s(:true))),
      :user_input => s(:call, s(:params), :[], s(:lit, :yaml_stuff))
  end

  def test_safe_yaml_load_option_false
    assert_warning :type => :warning,
      :warning_code => 25,
      :fingerprint => "2798cec372112fdecfadf2cb30b41635742d93c5b0bfc0ba71a3f69eb21b7f48",
      :warning_type => "Remote Code Execution",
      :line => 42,
      :message => /^`YAML\.load`\ called\ with\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:const, :YAML), :load, s(:call, s(:params), :[], s(:lit, :yaml_stuff)), s(:hash, s(:lit, :safe), s(:false))),
      :user_input => s(:call, s(:params), :[], s(:lit, :yaml_stuff))
  end

  def test_safe_yaml_load_option_missing
    assert_warning :type => :warning,
      :warning_code => 25,
      :fingerprint => "baffe1ec42a14c076b7c7bf676f833a397b879ee8c8ae4bc697b2bcef0355399",
      :warning_type => "Remote Code Execution",
      :line => 43,
      :message => /^`YAML\.load`\ called\ with\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:const, :YAML), :load, s(:call, s(:params), :[], s(:lit, :yaml_stuff))),
      :user_input => s(:call, s(:params), :[], s(:lit, :yaml_stuff))
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

  def test_command_injection_nonstandard_directory
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "374fcec0e44933e90ee710b9a3975e29134d8a3725e3d7d7ab5e0e8f0c09f5a4",
      :warning_type => "Command Injection",
      :line => 3,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "another_lib_dir/some_lib.rb",
      :code => s(:dxstr, "rm -rf ", s(:evstr, s(:lvar, :thing))),
      :user_input => s(:lvar, :thing)
  end

  def test_command_injection_with_temp_file_path
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "0e28d1629630acaf62f873043ad128de709ac423f86256bed8fa73fdc8756f20",
      :warning_type => "Command Injection",
      :line => 4,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/run_stuff.rb",
      :code => s(:dxstr, "cat ", s(:evstr, s(:call, s(:lvar, :temp_file), :path))),
      :user_input => s(:call, s(:lvar, :temp_file), :path)
  end

  def test_dynamic_render_path_renderable
    assert_no_warning :type => :warning,
      :warning_code => 15,
      :fingerprint => "50c648276617a57eafc0402e7a2f2c02a3d25d8b6c9ced62cd84294163595ff5",
      :warning_type => "Dynamic Render Path",
      :line => 12,
      :message => /^Render\ path\ contains\ parameter\ value/,
      :confidence => 2,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:render, :action, s(:call, s(:const, :TestComponent), :new, s(:call, s(:params), :require, s(:str, "name"))), s(:hash)),
      :user_input => s(:call, s(:params), :require, s(:str, "name"))
  end

  def test_dynamic_render_path_known_renderable_class
    assert_no_warning :type => :warning,
      :warning_code => 15,
      :fingerprint => "7e8ad12b494ba3e8617fb6a8d27aa10a4f944498c6236d07c31e6063b3c83fc5",
      :warning_type => "Dynamic Render Path",
      :line => 13,
      :message => /^Render\ path\ contains\ parameter\ value/,
      :confidence => 2,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:render, :action, s(:call, s(:const, :TestViewComponent), :new, s(:call, s(:params), :require, s(:str, "name"))), s(:hash)),
      :user_input => s(:call, s(:params), :require, s(:str, "name"))
  end

  def test_dynamic_render_path_fully_qualified_known_renderable_class
    assert_no_warning :check_name => "Render",
      :type => :warning,
      :warning_code => 15,
      :fingerprint => "2b82e2d4056b1d82a41245f21d22ea1e03ebdbbe1bd84df8e6095d23e43515fc",
      :warning_type => "Dynamic Render Path",
      :line => 14,
      :message => /^Render\ path\ contains\ parameter\ value/,
      :confidence => 2,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:render, :action, s(:call, s(:colon3, :TestViewComponent), :new, s(:call, s(:params), :require, s(:str, "name"))), s(:hash)),
      :user_input => s(:call, s(:params), :require, s(:str, "name"))
  end

  def test_dynamic_render_path_fully_qualified_ancestor_known_renderable_class
    assert_no_warning :check_name => "Render",
      :type => :warning,
      :warning_code => 15,
      :fingerprint => "224aa68d0c57766bfdfef3df66f361c2eecc95533d07b4a31fe08d1530854d7c",
      :warning_type => "Dynamic Render Path",
      :line => 15,
      :message => /^Render\ path\ contains\ parameter\ value/,
      :confidence => 2,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:render, :action, s(:call, s(:const, :TestViewComponentFullyQualifiedAncestor), :new, s(:call, s(:params), :require, s(:str, "name"))), s(:hash)),
      :user_input => s(:call, s(:params), :require, s(:str, "name"))
  end

  def test_dynamic_render_path_phlex_component
    assert_no_warning :type => :warning,
      :warning_code => 15,
      :warning_type => "Dynamic Render Path",
      :line => 87,
      :message => /^Render\ path\ contains\ parameter\ value/,
      :confidence => 2,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:render, :action, s(:call, s(:const, :TestPhlexComponent), :new, s(:call, s(:params), :require, s(:str, "name"))), s(:hash)),
      :user_input => s(:call, s(:params), :require, s(:str, "name"))
  end

  def test_dynamic_render_view_component_contrib
    assert_no_warning :type => :warning,
      :warning_code => 15,
      :warning_type => "Dynamic Render Path",
      :line => 90,
      :message => /^Render\ path\ contains\ parameter\ value/,
      :confidence => 2,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:render, :action, s(:call, s(:const, :TestViewComponentContrib), :new, s(:call, s(:params), :require, s(:str, "name"))), s(:hash)),
      :user_input => s(:call, s(:params), :require, s(:str, "name"))
  end

  def test_dynamic_render_path_dir_glob_filter
    assert_no_warning :type => :warning,
      :warning_code => 15,
      :fingerprint => "3ca5600705cf1e73b6213275bb2206480867176a80f0f1135a100019a29cb850",
      :warning_type => "Dynamic Render Path",
      :line => 29,
      :message => /^Render\ path\ contains\ parameter\ value/,
      :confidence => 1,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:render, :action, s(:dstr, "groups/", s(:evstr, s(:call, s(:params), :[], s(:lit, :template)))), s(:hash)),
      :user_input => s(:call, s(:params), :[], s(:lit, :template))
  end

  def test_mass_assignment_permit_bang_1
    assert_warning :type => :warning,
      :warning_code => 70,
      :fingerprint => "58e42d4ef79c278374a8456b1c034c7768e28b9a156e5602bb99a1105349f350",
      :warning_type => "Mass Assignment",
      :line => 93,
      :message => /^Specify exact keys allowed for mass assignment/,
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
      :message => /^Specify exact keys allowed for mass assignment/,
      :confidence => 1,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:params), :permit!),
      :user_input => nil
  end

  def test_mass_assignment_in_path_helper_false_positive
    assert_no_warning :type => :warning,
      :warning_code => 70,
      :fingerprint => "7802220237ed1e4c030fdc71d59bffd33fa8800adeb699e9d2105b00bc048d38",
      :warning_type => "Mass Assignment",
      :line => 32,
      :message => /^Parameters\ should\ be\ whitelisted\ for\ mas/,
      :confidence => 1,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:params), :permit!),
      :user_input => nil
  end

  def test_mass_assignment_global_allow_all_parameters
    assert_warning :type => :warning,
      :warning_code => 112,
      :fingerprint => "a02bb53bb433ffd7e52cfd58f9a3fdf20f53d082db36d2e47bf3c0aee32458ae",
      :warning_type => "Mass Assignment",
      :line => 2,
      :message => /^Mass assignment is globally enabled/,
      :confidence => 0,
      :relative_path => "config/initializers/allow_all_parameters.rb",
      :code => s(:attrasgn, s(:colon2, s(:const, :ActionController), :Parameters), :permit_all_parameters=, s(:true)),
      :user_input => nil
  end

  def test_mass_assignment_permit_bang_slice_false_positive
    assert_no_warning :type => :warning,
      :warning_code => 70,
      :fingerprint => "5c1aa277503e9c28dda97731136240ab07800348c4ac296c25789d65bd158373",
      :warning_type => "Mass Assignment",
      :line => 36,
      :message => /^Parameters\ should\ be\ whitelisted\ for\ mas/,
      :confidence => 1,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, s(:params), :permit!),
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

  def test_template_injection_1
    assert_warning :type => :warning,
      :warning_code => 117,
      :fingerprint => "fba898ebe85a030856f8553a3329c184ad6f9e16b1ecc8eb862d75f8b48d8189",
      :warning_type => "Template Injection",
      :line => 15,
      :message => /^Parameter\ value\ used\ directly\ in\ `ERB`\ t/,
      :confidence => 0,
      :relative_path => "app/models/user.rb",
      :code => s(:call, s(:const, :ERB), :new, s(:params)),
      :user_input => s(:params)
  end

  def test_http_verb_confusion_1
    assert_warning :type => :warning,
      :warning_code => 118,
      :fingerprint => "25c3c56a6e2026101731748e855b72413e91afb0fcc5c1d250253ede9d8ce6d9",
      :warning_type => "HTTP Verb Confusion",
      :line => 3,
      :message => /^Potential\ HTTP\ verb\ confusion\.\ `HEAD`\ is/,
      :confidence => 2,
      :relative_path => "app/controllers/accounts_controller.rb",
      :code => s(:if, s(:call, s(:call, nil, :request), :get?), nil, nil),
      :user_input => s(:call, s(:call, nil, :request), :get?)
  end

  def test_skip_dev_environment
    assert_no_warning :type => :warning,
      :warning_code => 13,
      :fingerprint => "a7759c4ad34056fffc847aff31c9b40d90803cd5637a7189b0edfd7615132f37",
      :warning_type => "Dangerous Eval",
      :line => 54,
      :message => /^Parameter\ value\ evaluated\ as\ code/,
      :confidence => 0,
      :relative_path => "app/controllers/groups_controller.rb",
      :code => s(:call, nil, :eval, s(:call, s(:params), :[], s(:lit, :x))),
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_dangerous_eval_as_method_target
    assert_warning :type => :warning,
      :warning_code => 13,
      :fingerprint => "3c4b94f3fc4ff4cfb005299349eb4f9a89832f35fc33ed9edc8481b98a047edb",
      :warning_type => "Dangerous Eval",
      :line => 27,
      :message => /^Parameter\ value\ evaluated\ as\ code/,
      :confidence => 0,
      :relative_path => "app/controllers/accounts_controller.rb",
      :code => s(:call, nil, :eval, s(:call, s(:params), :[], s(:lit, :x))),
      :user_input => s(:call, s(:params), :[], s(:lit, :x))
  end

  def test_unmaintained_dependency_ruby
    assert_warning check_name: "EOLRuby",
      type: :warning,
      warning_code: 121,
      fingerprint: "81776f151be34b9c42a5fc3bec249507a2acd9b64338e6f544a68559976bc5d5",
      warning_type: "Unmaintained Dependency",
      line: 4,
      message: /^Support\ for\ Ruby\ 2\.5\.3\ ended\ on\ 2021\-03\-/,
      confidence: 0,
      relative_path: "Gemfile"
  end
end
