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
      :template => 0,
      :generic => 9
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
      :line => 71,
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
      :line => 23,
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
      :line => 13,
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
      :line => 28,
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
      :line => 32,
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
      :line => 36,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb"
  end

  def test_command_injection_interpolated_ternary_safe
    assert_no_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "007232cf2f1dc81f49d8ae2b3e1d77b6491b6a7fcf82cfc424982e05b1cab9b5",
      :warning_type => "Command Injection",
      :line => 40,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb"
  end

  def test_command_injection_interpolated_conditional_dangerous
    assert_warning :type => :warning,
      :warning_code => 14,
      :fingerprint => "35e75c9db1462a5945016a6d4dbc195cba7b2d105a0ef71070bdd6f305a0efef",
      :warning_type => "Command Injection",
      :line => 44,
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
      :line => 48,
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
      :line => 61,
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
      :line => 67,
      :message => /^Possible\ command\ injection/,
      :confidence => 1,
      :relative_path => "lib/shell.rb",
      :code => s(:dxstr, "echo ", s(:evstr, s(:lvar, :exp))),
      :user_input => s(:lvar, :exp)
  end

  def test_cross_site_scripting_loofah_CVE_2018_8048
    assert_warning :type => :warning,
      :warning_code => 106,
      :fingerprint => "c8adc1c0caf2c9251d1d8de588fb949070212d0eed5e1580aee88bab2287b772",
      :warning_type => "Cross-Site Scripting",
      :line => 90,
      :message => /^Loofah\ 2\.1\.1\ is\ vulnerable\ \(CVE\-2018\-804/,
      :confidence => 1,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end

  def test_cross_site_scripting_CVE_2018_3741
    assert_warning :type => :warning,
      :warning_code => 107,
      :fingerprint => "e0636b950dd005468b5f9a0426ed50936e136f18477ca983cfc51b79e29f6463",
      :warning_type => "Cross-Site Scripting",
      :line => 125,
      :message => /^rails\-html\-sanitizer\ 1\.0\.3\ is\ vulnerable/,
      :confidence => 1,
      :relative_path => "Gemfile.lock",
      :user_input => nil
  end
end
