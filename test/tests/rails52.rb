require_relative '../test'

class Rails52Tests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    @@report ||= BrakemanTester.run_scan "rails5.2", "Rails 5.2", run_all_checks: true
  end

  def expected
    @@expected ||= {
      :controller => 0,
      :model => 0,
      :template => 7,
      :generic => 24
    }
  end

  def test_cross_site_request_forgery_false_positive
    assert_no_warning :type => :controller,
      :warning_code => 7,
      :fingerprint => "6f5239fb87c64764d0c209014deb5cf504c2c10ee424bd33590f0a4f22e01d8f",
      :warning_type => "Cross-Site Request Forgery",
      :message => /^'protect_from_forgery'\ should\ be\ called\ /,
      :confidence => 0,
      :relative_path => "app/controllers/application_controller.rb"
  end

  def test_query_with_symbolize_keys
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "b7614315999c9f0db62649515da3bc9ce32ec418d69ea13af0564841392c98af",
      :warning_type => "SQL Injection",
      :line => 9,
      :message => /^Possible SQL injection/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb"
  end

  def test_sql_injection_not
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "659ce3a1ad4a44065f64f44e73c857c80c9505ecf74a3ebe40f3454dc7185845",
      :warning_type => "SQL Injection",
      :line => 3,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 2,
      :relative_path => "app/models/user.rb",
      :code => s(:call, s(:call, nil, :where), :not, s(:dstr, "blah == ", s(:evstr, s(:lvar, :thing)))),
      :user_input => s(:lvar, :thing)
  end

  def test_sql_injection_string_freeze
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "b1ed6e8858db8a9a176fba44374a9a43c6277ea5df3ed04236a5870eed44e43c",
      :warning_type => "SQL Injection",
      :line => 11,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/user.rb",
      :code => s(:call, s(:call, s(:call, s(:self), :class), :select, s(:dstr, "", s(:evstr, s(:call, s(:str, "my_table_alias"), :freeze)), s(:str, ".*"))), :from, s(:dstr, "", s(:evstr, s(:call, nil, :table_name)), s(:str, " AS "), s(:evstr, s(:call, s(:str, "my_table_alias"), :freeze)))),
      :user_input => s(:call, s(:str, "my_table_alias"), :freeze)
  end

  def test_sql_injection_with_array_map
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "d3e36e5e530dc926b4fd38c605cf39341bf9e48169310f34ac439caf129e1f6f",
      :warning_type => "SQL Injection",
      :line => 76,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 2,
      :relative_path => "lib/shell.rb",
      :code => s(:call, s(:lvar, :base_scope), :where, s(:dstr, "", s(:evstr, s(:lvar, :exp)), s(:str, " ILIKE '%foo%'"))),
      :user_input => s(:lvar, :exp)
  end

  def test_sql_injection_safe_literal_to_s_singularize
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "4de07c156fa4b7694024871f100409e41fbcac4f65813a34ba749e1751b95204",
      :warning_type => "SQL Injection",
      :line => 16,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 2,
      :relative_path => "app/models/user.rb",
      :code => s(:call, s(:call, nil, :articles), :sum, s(:dstr, "calculated_", s(:evstr, s(:call, s(:call, s(:lit, :BRAKEMAN_SAFE_LITERAL), :to_s), :singularize)), s(:str, "_cents * quantity"))),
      :user_input => s(:call, s(:call, s(:lit, :BRAKEMAN_SAFE_LITERAL), :to_s), :singularize)
  end

  def test_sql_injection_foreign_key
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "efc0a7f6a2f171db9cd6369da3335f0250478f9f50603118884f4d2ca0ca5161",
      :warning_type => "SQL Injection",
      :line => 24,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/models/user.rb",
      :code => s(:call, s(:const, :User), :joins, s(:dstr, "INNER JOIN <complex join involving custom SQL and ", s(:evstr, s(:call, s(:call, nil, :reflect_on_association, s(:lit, :foos)), :foreign_key)), s(:str, " interpolation>"))),
      :user_input => s(:call, s(:call, nil, :reflect_on_association, s(:lit, :foos)), :foreign_key)
  end

  def test_sql_injection_user_input
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "f7affe2dfe9e3a48f39f1fb86224e150e60555a73f2e78fb499eadd298233625",
      :warning_type => "SQL Injection",
      :line => 31,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:const, :User), :find_by_sql, s(:dstr, "SELECT ", s(:evstr, s(:iter, s(:call, s(:iter, s(:call, s(:call, s(:const, :Something), :selection), :select), s(:args, :x), s(:call, nil, :some_condition?, s(:lvar, :x))), :map), s(:args, :x), s(:dstr, "", s(:evstr, s(:call, s(:const, :User), :table_name)), s(:str, "."), s(:evstr, s(:lvar, :x))))), s(:str, ".name"), s(:str, " where name = "), s(:evstr, s(:call, s(:params), :[], s(:lit, :name))))),
      :user_input => s(:iter, s(:call, s(:iter, s(:call, s(:call, s(:const, :Something), :selection), :select), s(:args, :x), s(:call, nil, :some_condition?, s(:lvar, :x))), :map), s(:args, :x), s(:dstr, "", s(:evstr, s(:call, s(:const, :User), :table_name)), s(:str, "."), s(:evstr, s(:lvar, :x))))
  end

  def test_sql_injection_splat
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "c869a301cba116872eac10eda8b3f99dff818c5014cd2552110a8eb4dcdfe661",
      :warning_type => "SQL Injection",
      :line => 35,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 1,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:const, :Person), :where, s(:splat, s(:call, s(:params), :[], s(:lit, :foo)))),
      :user_input => s(:call, s(:params), :[], s(:lit, :foo))
  end

  def test_sql_injection_kwsplat
    assert_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "624ecefdd9521b00ceb9ae845c523fe456c6494d59f8fa2217474a1d4d46e512",
      :warning_type => "SQL Injection",
      :line => 39,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:const, :User), :where, s(:hash, s(:kwsplat, s(:call, s(:params), :[], s(:lit, :foo))))),
      :user_input => s(:call, s(:params), :[], s(:lit, :foo))
  end

  def test_ignoring_freeze_generally
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "fdfde80ab27695c4a296f68f953391581df6e9b5568d921622982c32baffaa25",
      :warning_type => "SQL Injection",
      :line => 18,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 2,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:const, :Person), :where, s(:dstr, "", s(:evstr, s(:lvar, :foo)), s(:str, " >= 1"))),
      :user_input => s(:lvar, :foo)
  end

  def test_treat_if_not_like_unless
    assert_no_warning :type => :warning,
      :warning_code => 0,
      :fingerprint => "c5788857ecda6ae28a0cf4db2823a49e5dbcd029a65c9a8d6d750e43d4596268",
      :warning_type => "SQL Injection",
      :line => 24,
      :message => /^Possible\ SQL\ injection/,
      :confidence => 2,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:const, :Person), :where, s(:dstr, "", s(:evstr, s(:lvar, :foo)), s(:str, " >= 1"))),
      :user_input => s(:lvar, :foo)
  end

  def test_command_injection_1
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "d8881688ca97faef7a0f300a902237ea201e52a511a45561dcd7462ef85ae720",
      :warning_type => "Command Injection",
      :line => 7,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/initthing.rb",
      :code => s(:dxstr, "", s(:evstr, s(:ivar, :@blah))),
      :user_input => s(:ivar, :@blah)
  end

  def test_command_injection_in_job
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "e712e2741ad78f4e947bec84f36a0d703849d3b0facdabd8cc74851d7b702a48",
      :warning_type => "Command Injection",
      :line => 3,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "app/jobs/delete_stuff_job.rb",
      :code => s(:dxstr, "rm -rf ", s(:evstr, s(:lvar, :file))),
      :user_input => s(:lvar, :file)
  end

  def test_command_injection_shellwords
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "89b886281c6329f5c5f319932d98ea96527d50f1d188fde9fd85ff93130b7c50",
      :warning_type => "Command Injection",
      :line => 9,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:dxstr, "dig +short -x ", s(:evstr, s(:call, s(:const, :Shellwords), :shellescape, s(:lvar, :ip))), s(:str, " @"), s(:evstr, s(:call, s(:const, :Shellwords), :shellescape, s(:lvar, :one))), s(:str, " -p "), s(:evstr, s(:call, s(:const, :Shellwords), :escape, s(:lvar, :two)))),
      :user_input => s(:call, s(:const, :Shellwords), :shellescape, s(:lvar, :ip))
  end

  def test_command_injection_nested_shellwords
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "acb19548a2a44c3070d35c62754216f4b3365f372d6004470417cca587af0f47",
      :warning_type => "Command Injection",
      :line => 28,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:call, nil, :system, s(:dstr, "echo ", s(:evstr, s(:call, s(:const, :Shellwords), :escape, s(:dstr, "", s(:evstr, s(:call, nil, :file_prefix)), s(:str, ".txt")))))),
      :user_input => s(:call, nil, :file_prefix)
  end

  def test_command_injection_backticks_as_target
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "9af991a12b23b815013ce0c69727b7a14cfb08e62f4e66a8851513af7cc6a757",
      :warning_type => "Command Injection",
      :line => 18,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:dxstr, "echo ", s(:evstr, s(:lvar, :path))),
      :user_input => s(:lvar, :path)
  end

  def test_command_injection_array_join
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "478a39b6379df61bf0b016f435d054f279353e4fcd048304105152f6203fbdaa",
      :warning_type => "Command Injection",
      :line => 33,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:call, nil, :system, s(:dstr, "ruby ", s(:evstr, s(:call, nil, :method_that_returns_user_input)), s(:str, " --some-flag"))),
      :user_input => s(:call, nil, :method_that_returns_user_input)
  end

  def test_command_injection_as_target
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "18e51f5a40dc0e63a90908e88ec5f2ed585fa3a645622f997026ada323cf7552",
      :warning_type => "Command Injection",
      :line => 37,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:call, nil, :system, s(:dstr, "echo ", s(:evstr, s(:call, nil, :foo)))),
      :user_input => s(:call, nil, :foo)
  end

  def test_command_injection_interpolated_conditional_safe
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "eae19504b13ab3f112216fa589e1ec19dfce6df912bd43f00066b77c94c10568",
      :warning_type => "Command Injection",
      :line => 41,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb"
  end

  def test_command_injection_interpolated_ternary_safe
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "007232cf2f1dc81f49d8ae2b3e1d77b6491b6a7fcf82cfc424982e05b1cab9b5",
      :warning_type => "Command Injection",
      :line => 45,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb"
  end

  def test_command_injection_interpolated_conditional_dangerous
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "35e75c9db1462a5945016a6d4dbc195cba7b2d105a0ef71070bdd6f305a0efef",
      :warning_type => "Command Injection",
      :line => 49,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:dxstr, "echo ", s(:evstr, s(:if, s(:call, nil, :foo), s(:call, nil, :bar), nil)), s(:str, " baz")),
      :user_input => s(:call, nil, :bar)
  end

  def test_command_injection_interpolated_ternary_dangerous
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "a88fd53a2f217af569c90edcef2d1b086a347b100d67cae52f519073050d48af",
      :warning_type => "Command Injection",
      :line => 53,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:dxstr, "echo ", s(:evstr, s(:if, s(:call, nil, :foo), s(:str, "bar"), s(:call, nil, :bar))), s(:str, " baz")),
      :user_input => s(:call, nil, :bar)
  end

  def test_command_injection_with_hash_unknown_key_access
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "d24b0ba3ecb378e00bc0c8034eb2651f145ec6247f7471f8a41b31d44d4cdd33",
      :warning_type => "Command Injection",
      :line => 66,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:dxstr, "", s(:evstr, s(:or, s(:call, s(:const, :COMMANDS), :[], s(:lvar, :arg)), s(:call, s(:const, :MORE_COMMANDS), :[], s(:lvar, :arg)))), s(:str, " file1.txt")),
      :user_input => s(:call, s(:const, :COMMANDS), :[], s(:lvar, :arg))
  end

  def test_command_injection_with_array_each
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "760cf49f3f216b99e9720a8282ace8096c3b844ebd1da16cf20478d00449cd90",
      :warning_type => "Command Injection",
      :line => 72,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:dxstr, "echo ", s(:evstr, s(:lvar, :exp))),
      :user_input => s(:lvar, :exp)
  end

  def test_command_injection_shell_escape_model
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "fc6e48ece7bd1e6a9e6d03cdedfcdf7818c86515b563a9a09bb49c5da00d8324",
      :warning_type => "Command Injection",
      :line => 82,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "lib/shell.rb",
      :code => s(:call, s(:const, :Open3), :capture2e, s(:str, "ls"), s(:call, s(:const, :Shellwords), :escape, s(:call, s(:call, s(:const, :User), :new), :z))),
      :user_input => s(:call, s(:call, s(:const, :User), :new), :z)

    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "781301c915efbc0f26482d8114744b062001946fb9450c969220fcf4f516ac2f",
      :warning_type => "Command Injection",
      :line => 85,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "lib/shell.rb",
      :code => s(:dxstr, "ls ", s(:evstr, s(:call, s(:const, :Shellwords), :escape, s(:call, s(:call, s(:const, :User), :new), :z)))),
      :user_input => s(:call, s(:call, s(:const, :User), :new), :z)
  end

  def test_command_injection_with__file__
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "8aeaa50052306c0c79e3b1ece079ba369e30356658b455b049da9543fd729d75",
      :warning_type => "Command Injection",
      :line => 90,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:dxstr, "cp lib/shell.rb ", s(:evstr, s(:call, nil, :somewhere_else))),
      :user_input => s(:call, nil, :somewhere_else)
  end

  def test_command_injection_percent_W
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :warning_type => "Command Injection",
      :line => 95,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:call, nil, :system, s(:splat, s(:array, s(:str, "foo"), s(:str, "bar"), s(:dstr, "", s(:evstr, s(:call, nil, :value)))))),
      :user_input => s(:call, nil, :value)
  end

  def test_command_injection_with_concatenation
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "6a8f4711d1bbd58964c536edb77372c1d402ee18ed558390d46d60c57920d614",
      :warning_type => "Command Injection",
      :line => 103,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:call, nil, :system, s(:call, s(:str, "echo "), :+, s(:call, nil, :foo))),
      :user_input => s(:call, nil, :foo)
  end

  def test_dash_c_command_injection_with_concatenation
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "cbafca7ab394a7454815dc0c45e873ce35a23093431ef414f2cfad40ec37fb98",
      :warning_type => "Command Injection",
      :line => 115,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:call, nil, :system, s(:str, "bash"), s(:str, "-c"), s(:call, s(:str, "echo "), :+, s(:call, nil, :foo))),
      :user_input => s(:call, nil, :foo)
  end

  def test_dash_c_command_injection_with_popen
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "da6ffe8f2fadd19479a1ae5e060b76e04f517cbeb6c54c47b59d63196e7b05aa",
      :warning_type => "Command Injection",
      :line => 123,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "lib/shell.rb",
      :code => s(:call, s(:const, :IO), :popen, s(:array, s(:str, "bash"), s(:str, "-c"), s(:call, s(:params), :[], s(:lit, :foo)))),
      :user_input => s(:call, s(:params), :[], s(:lit, :foo))
  end

  def test_command_injection_concatenation_with_popen
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "b801bc63d43acc99bffcb4c669a1d0d6acc0724cc7267d5739f9ec31c4067467",
      :warning_type => "Command Injection",
      :line => 127,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:call, s(:const, :IO), :popen, s(:call, s(:str, "ls "), :+, s(:call, nil, :foo))),
      :user_input => s(:call, nil, :foo)
  end

  def test_command_injection_ignored_in_vendor_dir
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :warning_type => "Command Injection",
      :line => 3,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "vendor/vendored_thing.rb",
      :code => s(:dxstr, "rm -rf ", s(:evstr, s(:call, nil, :stuff))),
      :user_input => s(:call, nil, :stuff)
  end

  def test_cross_site_scripting_haml_sass
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "45a1c26b6a6b4735351d7d6ce91e33e9b7295865e7e8e49cbafd5945c9429862",
      :warning_type => "Cross-Site Scripting",
      :line => 4,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "app/views/users/one.html.haml",
      :code => s(:call, s(:call, s(:const, :User), :find, s(:call, s(:params), :[], s(:lit, :id))), :name),
      :user_input => nil
  end

  def test_cross_site_scripting_slim_sass
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "4a2b104710afbfb3861dc1e6f1b4b6e2459e422662561e009722b31e6e8f6d87",
      :warning_type => "Cross-Site Scripting",
      :line => 6,
      :message => /^Unescaped\ model\ attribute/,
      :confidence => 0,
      :relative_path => "app/views/users/two.html.slim",
      :code => s(:call, s(:call, s(:const, :User), :find, s(:call, s(:params), :[], s(:lit, :id))), :name),
      :user_input => nil
  end

  def test_cross_site_scripting_kwsplat_known_values
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "bc1e6c1ff0c94366d1936050698bad21b33cb7377528169a18ef609c39c373b9",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/users/_foo.html.haml",
      :code => s(:call, s(:call, nil, :params), :[], s(:lit, :x)),
      :user_input => nil
  end

  def test_cross_site_scripting_kwsplat_unknown_values
    assert_warning :type => :template,
      :warning_code => 2,
      :fingerprint => "f4393261a50f25e93f61ff8387643e110a2c386f9063806c99dadc8226eb6c0e",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/views/users/_foo2.html.haml",
      :code => s(:call, s(:call, nil, :params), :[], s(:lit, :x)),
      :user_input => nil
  end

  def test_cross_site_scripting_link_to_with_block
    assert_warning :type => :template,
      :warning_code => 4,
      :fingerprint => "caefec37f50032631e8b0352437a13f792076ef2d7460040c96aa68c5ac1c863",
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unsafe\ parameter\ value\ in\ `link_to`\ href/,
      :confidence => 0,
      :relative_path => "app/views/users/link.html.erb",
      :code => s(:call, nil, :link_to, s(:call, s(:call, nil, :params), :[], s(:lit, :x))),
      :user_input => s(:call, s(:call, nil, :params), :[], s(:lit, :x))
  end

  def test_cross_site_scripting_not_not_false_positive
    assert_no_warning :type => :template,
      :warning_code => 2,
      :warning_type => "Cross-Site Scripting",
      :line => 1,
      :message => /^Unescaped\ parameter\ value/,
      :confidence => 2,
      :relative_path => "app/views/users/not_not.html.erb",
      :user_input => s(:call, s(:call, s(:call, s(:params), :[], s(:lit, :header_row)), :!), :!)
  end

  def test_remote_code_execution_oj_load
    assert_warning :type => :warning,
      :warning_code => 25,
      :fingerprint => "97ecaa5677c8eadaed09217a704e59092921fab24cc751e05dfb7b167beda2cf",
      :warning_type => "Remote Code Execution",
      :line => 51,
      :message => /^`Oj\.load`\ called\ with\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:const, :Oj), :load, s(:call, s(:params), :[], s(:lit, :json))),
      :user_input => s(:call, s(:params), :[], s(:lit, :json))
  end

  def test_remote_code_execution_oj_load_mode
    assert_warning :type => :warning,
      :warning_code => 25,
      :fingerprint => "006ac5fe3834bf2e73ee51b67eb111066f618be46e391d493c541ea2a906a82f",
      :warning_type => "Remote Code Execution",
      :line => 52,
      :message => /^`Oj\.load`\ called\ with\ parameter\ value/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:const, :Oj), :load, s(:call, s(:params), :[], s(:lit, :json)), s(:hash, s(:lit, :mode), s(:lit, :object))),
      :user_input => s(:call, s(:params), :[], s(:lit, :json))
  end

  def test_remote_code_execution_oj_object_load
    assert_warning :type => :warning,
      :warning_code => 25,
      :fingerprint => "3bc375c9cb79d8bcd9e7f1c09a574fa3deeab17f924cf20455cbd4c15e9c66eb",
      :warning_type => "Remote Code Execution",
      :line => 53,
      :message => /^`Oj\.object_load`\ called\ with\ parameter\ v/,
      :confidence => 0,
      :relative_path => "app/controllers/users_controller.rb",
      :code => s(:call, s(:const, :Oj), :object_load, s(:call, s(:params), :[], s(:lit, :json)), s(:hash, s(:lit, :mode), s(:lit, :strict))),
      :user_input => s(:call, s(:params), :[], s(:lit, :json))
  end

  def test_remote_code_execution_cookie_serialization_config
    assert_warning :type => :warning,
      :warning_code => 110,
      :fingerprint => "9ae68e59cfee3e5256c0540dadfeb74e6b72c91997fdb60411063a6e8518144a",
      :warning_type => "Remote Code Execution",
      :line => 5,
      :message => /^Use\ of\ unsafe\ cookie\ serialization\ strat/,
      :confidence => 1,
      :relative_path => "config/initializers/cookies_serializer.rb",
      :code => s(:attrasgn, s(:call, s(:call, s(:call, s(:const, :Rails), :application), :config), :action_dispatch), :cookies_serializer=, s(:lit, :hybrid)),
      :user_input => nil
  end

  def test_missing_encryption_force_ssl
    assert_warning :type => :warning,
      :warning_code => 109,
      :fingerprint => "6a26086cd2400fbbfb831b2f8d7291e320bcc2b36984d2abc359e41b3b63212b",
      :warning_type => "Missing Encryption",
      :line => 50,
      :message => /^The\ application\ does\ not\ force\ use\ of\ HT/,
      :confidence => 0,
      :relative_path => "config/environments/production.rb",
      :code => nil,
      :user_input => nil
  end

  def test_cross_site_scripting_loofah_CVE_2018_8048
    assert_warning check_name: "SanitizeMethods",
      type: :warning,
      warning_code: 106,
      fingerprint: "cdfb1541fdcc9cdcf0784ce5bd90013dc39316cb822eedea3f03b2521c06137f",
      warning_type: "Cross-Site Scripting",
      line: 90,
      message: /^loofah\ gem\ 2\.1\.1\ is\ vulnerable\ \(CVE\-2018/,
      confidence: 0,
      relative_path: "Gemfile.lock",
      code: nil,
      user_input: nil
  end

  def test_cross_site_scripting_CVE_2018_3741
    assert_warning check_name: "SanitizeMethods",
      type: :warning,
      warning_code: 107,
      fingerprint: "3e35a6afcd1a8a14894cf26a7f00d4e895f0583bbc081d45e5bd28c4b541b7e6",
      warning_type: "Cross-Site Scripting",
      line: 125,
      message: /^rails\-html\-sanitizer\ 1\.0\.3\ is\ vulnerable/,
      confidence: 0,
      relative_path: "Gemfile.lock",
      code: nil,
      user_input: nil
  end

  def test_cross_site_scripting_CVE_2022_32209_sanitize_call
    assert_warning check_name: "SanitizeConfigCve",
      type: :template,
      warning_code: 124,
      fingerprint: "381dbd3ff41d8e8a36bc13ea1943fbf8f8d70774724c9f1be7b0581b88d1d3f5",
      warning_type: "Cross-Site Scripting",
      line: 9,
      message: /^rails\-html\-sanitizer\ 1\.0\.3\ is\ vulnerable/,
      confidence: 0,
      relative_path: "app/views/users/one.html.haml",
      code: s(:call, nil, :sanitize, s(:call, s(:call, s(:const, :User), :find, s(:call, s(:params), :[], s(:lit, :id))), :bio), s(:hash, s(:lit, :tags), s(:array, s(:str, "style"), s(:lit, :select)))),
      user_input: nil
  end

  def test_command_injection_ignored_in_stdin
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "98e72a863c59b1a9dd0024ef645ede1677e87123ac57b7b2d54ca704aba8f8e1",
      :warning_type => "Command Injection",
      :line => 135,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "lib/shell.rb"

    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "a8ac4ba6f5c56040bb21bb8a2a69a003a1a37b17822209133accb92bbaf1a19b",
      :warning_type => "Command Injection",
      :line => 136,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "lib/shell.rb"

    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "775dbae94ae590e818d94bcef5d035b46cbc0f72c5c9cb568cfca20a746ed290",
      :warning_type => "Command Injection",
      :line => 137,
      :message => /^Possible\ command\ injection/,
      :confidence => 0,
      :relative_path => "lib/shell.rb"
  end

  def test_unmaintained_dependency_ruby
    assert_warning check_name: "EOLRuby",
      type: :warning,
      warning_code: 121,
      fingerprint: "edf687f759ec9765bd5db185dbc615c80af77d6e7e19386fc42934e7a80307af",
      warning_type: "Unmaintained Dependency",
      line: 1,
      message: /^Support\ for\ Ruby\ 2\.3\.1\ ended\ on\ 2019\-03\-/,
      confidence: 0,
      relative_path: ".ruby-version",
      code: nil,
      user_input: nil
  end
end

class Rails52WithVendorTests < Minitest::Test
  include BrakemanTester::FindWarning

  def report
    @@report ||= BrakemanTester.run_scan "rails5.2", "Rails 5.2", skip_vendor: false 
  end

  def test_command_injection_ignored_vendor_dir
    assert_warning :type => :warning,
      :warning_code => 14,
      :warning_type => "Command Injection",
      :line => 3,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "vendor/vendored_thing.rb",
      :code => s(:dxstr, "rm -rf ", s(:evstr, s(:call, nil, :stuff))),
      :user_input => s(:call, nil, :stuff)
  end
end
