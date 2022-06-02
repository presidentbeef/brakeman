require_relative '../test'

class ActiveRecordOnlyTests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def expected
    @expected ||= {
      :controller => 0,
      :model => 0,
      :template => 0,
      :warning => 1 }
  end

  def report
    @@report ||=
      Date.stub :today, Date.parse('2022-04-05') do
        BrakemanTester.run_scan "active_record_only", "ActiveRecordOnly"
      end
  end

  def test_no_attribute_restriction
    assert_no_warning :type => :model,
      :warning_code => 19,
      :fingerprint => "b660c00ebcf323130f61f3f402bd8ea067b472c785f9b069e1317216aa94360f",
      :warning_type => "Attribute Restriction",
      :line => 5,
      :message => /^Mass\ assignment\ is\ not\ restricted\ using\ /,
      :confidence => 0,
      :relative_path => "app/models/book.rb",
      :code => nil,
      :user_input => nil
  end

  def test_unmaintained_dependency_1
    assert_warning check_name: "EOLRails",
      type: :warning,
      warning_code: 122,
      fingerprint: "ae8b91c42bce1bcab89b00b4d4f44479bd4376726f36207abc94d896eddd2320",
      warning_type: "Unmaintained Dependency",
      line: nil,
      message: /^Support\ for\ Rails\ 5\.2\.4\.3\ ends\ on\ 2022\-0/,
      confidence: 2,
      relative_path: "Gemfile",
      code: nil,
      user_input: nil
  end
end
