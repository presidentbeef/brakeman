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
      warning:    5
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

  def test_cross_site_scripting_haml6_attribute_builder
    assert_no_warning check_name: "CrossSiteScripting",
      type: :template,
      warning_code: 2,
      fingerprint: "26ce9d920c75d29438b84cd3a45efdf4a7235d883d133937445c31c627bbc791",
      warning_type: "Cross-Site Scripting",
      line: 1,
      message: /^Unescaped\ model\ attribute/,
      confidence: 2,
      relative_path: "app/views/users/dom_id.haml",
      code: s(:call, s(:colon2, s(:colon3, :Haml), :AttributeBuilder), :build_id, s(:true), s(:call, nil, :dom_id, s(:call, s(:const, :User), :first))),
      user_input: s(:call, s(:const, :User), :first)
  end

  def test_sql_injection_permit_or_false_positive
    assert_no_warning check_name: "SQL",
      type: :warning,
      warning_code: 0,
      fingerprint: "ad3963321ca8cbee045dce7efd357265432d14700f6cfb791b22da0395ad4fb9",
      warning_type: "SQL Injection",
      line: 74,
      message: /^Possible\ SQL\ injection/,
      confidence: 0,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, s(:const, :Thing), :find_by, s(:or, s(:call, s(:params), :permit, s(:lit, :foo_uid)), s(:hash, s(:lit, :id), s(:call, s(:params), :require, s(:lit, :model_id))))),
      user_input: s(:call, s(:params), :permit, s(:lit, :foo_uid))
  end

  def test_sql_injection_count_false_positive
    assert_no_warning check_name: "SQL",
      type: :warning,
      warning_code: 0,
      fingerprint: "cd09d75803f54d86ed5479758dcbb82c2ca9a29626fecd01a2bb5000b63b3aa6",
      warning_type: "SQL Injection",
      line: 78,
      message: /^Possible\ SQL\ injection/,
      confidence: 2,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, s(:gvar, :$stats), :count, s(:dstr, "thing.", s(:evstr, s(:call, nil, :variable))), s(:hash, s(:lit, :tags), s(:hash, s(:lit, :cool), s(:str, "stuff")))),
      user_input: s(:call, nil, :variable)
  end

  def test_sql_injection_count_less_false_positive
    assert_warning check_name: "SQL",
      type: :warning,
      warning_code: 0,
      fingerprint: "3f3281fe16319fd58d1bbd66515c61aa0962c1b7ab5f79421ed1c113271c9204",
      warning_type: "SQL Injection",
      line: 79,
      message: /^Possible\ SQL\ injection/,
      confidence: 1,
      relative_path: "app/controllers/users_controller.rb",
      code: s(:call, s(:call, nil, :not_ar_model), :count, s(:dstr, "something - ", s(:evstr, s(:call, s(:params), :[], s(:lit, :x))))),
      user_input: s(:call, s(:params), :[], s(:lit, :x))
  end
end
