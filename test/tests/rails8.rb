require_relative "../test"

class Rails8Tests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    @@report ||=
      Date.stub :today, Date.parse("2024-05-13") do
        BrakemanTester.run_scan "rails8", "Rails 8", run_all_checks: true, use_prism: false
      end
  end

  def expected
    @@expected ||= {
      controller: 0,
      model:      0,
      template:   2,
      warning:    5,
    }
  end

  def test_dangerous_eval_1
    assert_warning check_name: "Evaluation",
      type: :warning,
      warning_code: 13,
      fingerprint: "00a0720a22562960da1d793140ccae5987da210d45fb8478daabad13a5901130",
      warning_type: "Dangerous Eval",
      line: 7,
      message: /^Dynamic\ code\ evaluation/,
      confidence: 2,
      relative_path: "lib/evals.rb",
      code: s(:call, nil, :eval, s(:call, nil, :anything)),
      user_input: nil
  end

  def test_dangerous_eval_2
    assert_warning check_name: "Evaluation",
      type: :warning,
      warning_code: 13,
      fingerprint: "c9b3bb7b8898b84a0d82bf59a110b8259d4a7796a092aecda9910c8a02d7ae5e",
      warning_type: "Dangerous Eval",
      line: 4,
      message: /^Dynamic\ string\ evaluated\ as\ code/,
      confidence: 2,
      relative_path: "lib/evals.rb",
      code: s(:call, nil, :instance_eval, s(:dstr, "interpolated ", s(:evstr, s(:call, nil, :string)), s(:str, " - warning"))),
      user_input: nil
  end

  def test_dangerous_eval_3
    assert_warning check_name: "Evaluation",
      type: :warning,
      warning_code: 13,
      fingerprint: "6e08d62e8ad637151c2d28872e9e55fd872d4ae19ba511f72d80be7525f1509c",
      warning_type: "Dangerous Eval",
      line: 17,
      message: /^Dynamic\ string\ evaluated\ as\ code/,
      confidence: 2,
      relative_path: "lib/evals.rb",
      code: s(:call, nil, :eval, s(:dstr, "interpolate ", s(:evstr, s(:lvar, :something)))),
      user_input: nil
  end

  def test_plain_marshal_load_weak_warning
    assert_warning check_name: "Deserialize",
      type: :warning,
      warning_code: 25,
      fingerprint: "458ac9bba693eae0b1d311627d59101dceac803c578bd1da7d808cb333c75068",
      warning_type: "Remote Code Execution",
      line: 6,
      message: /^Use\ of\ `Marshal\.load`\ may\ be\ dangerous/,
      confidence: 2,
      relative_path: "app/controllers/application_controller.rb",
      code: s(:call, s(:const, :Marshal), :load, s(:call, nil, :something)),
      user_input: nil
  end

  def test_dangerous_eval_plain_strings
    assert_no_warning check_name: "Evaluation",
      type: :warning,
      warning_code: 13,
      warning_type: "Dangerous Eval",
      line: 22,
      message: /^Dynamic\ string\ evaluated\ as\ code/,
      confidence: 2,
      relative_path: "lib/evals.rb"
      # code: s(:call, nil, :class_eval, s(:dstr, "        def method_that_is_", s(:evstr, s(:lit, :BRAKEMAN_SAFE_LITERAL)), s(:str, "\n          puts suffix\n        end\n"))),
  end

  def test_cross_site_scripting_render_model_partial
    assert_warning check_name: "CrossSiteScripting",
      type: :template,
      warning_code: 2,
      fingerprint: "08a968d826da16ddaffcf8393d6ed50d30a3caea4b625dabf888a5a8b699453d",
      warning_type: "Cross-Site Scripting",
      line: 4,
      message: /^Unescaped\ model\ attribute/,
      confidence: 0,
      relative_path: "app/views/users/_user.html.erb",
      code: s(:call, s(:call, s(:const, :User), :new, s(:call, nil, :user_params)), :name),
      user_input: nil
  end

  def test_cross_site_scripting_render_model_as_collection
    assert_warning check_name: "CrossSiteScripting",
      type: :template,
      warning_code: 2,
      fingerprint: "27817dcbdd924e1772bd98bcdd6063486a633cf8c1b84353dcbf1dde23904a94",
      warning_type: "Cross-Site Scripting",
      line: 1,
      message: /^Unescaped\ model\ attribute/,
      confidence: 0,
      relative_path: "app/views/things/_thing.html.erb",
      code: s(:call, s(:call, s(:const, :Thing), :new), :name),
      user_input: nil
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
end
