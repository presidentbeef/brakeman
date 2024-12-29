require_relative "../test"

class Rails8Tests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def report
    @@report ||=
      Date.stub :today, Date.parse("2024-05-13") do
        BrakemanTester.run_scan "rails8", "Rails 8", run_all_checks: true, use_prism: true
      end
  end

  def expected
    @@expected ||= {
      controller: 0,
      model:      0,
      template:   0,
      warning:    2
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
end
