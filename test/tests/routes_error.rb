require_relative '../test'
require 'brakeman/rescanner'

class BrakemanTests < Minitest::Test
  include BrakemanTester::RescanTestHelper

  def test_parse_error_in_routes_rb
    before_rescan_of "config/routes.rb", "rails5.2" do
      write_file "config/routes.rb", "x = "
    end

    @rescanner.tracker.errors.select { |e| e[:exception].is_a? Racc::ParseError and e[:error].include? "routes.rb" }.each do |e|
      # Check that file path is being reported correctly by parser
      assert_includes e[:error], "config/routes.rb"
    end
  end
end
