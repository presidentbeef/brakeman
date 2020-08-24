require_relative '../test'

class ActiveRecordOnlyTests < Minitest::Test
  include BrakemanTester::FindWarning
  include BrakemanTester::CheckExpected

  def expected
    @expected ||= {
      :controller => 0,
      :model => 0,
      :template => 0,
      :warning => 0 }
  end

  def report
    @@report ||= BrakemanTester.run_scan "active_record_only", "ActiveRecordOnly"
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

end
