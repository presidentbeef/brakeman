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
      :generic => 7
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
