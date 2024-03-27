require_relative '../test'
require 'brakeman/rescanner'
require 'json'

class JSONCompareTests < Minitest::Test
  include BrakemanTester::RescanTestHelper
  include BrakemanTester::DiffHelper

  def test_sanity
    json_report = 'test-report.json'
    ignored_warnings = [
      'cd83ecf615b17f849ba28050e7faf1d54f218dfa9435c3f65f47cb378c18cf98',
      'abcdef01234567890ba28050e7faf1d54f218dfa9435c3f65f47cb378c18cf98'
    ]

    # Here I go, abusing the rescan functionality again.
    before_rescan_of ['app/models/account.rb', json_report], 'rails4' do |app_dir|
      report_file = File.join(app_dir, json_report)

      Brakeman.run(app_path: app_dir,
                   parallel_checks: false,
                   output_files: [report_file])

      remove 'app/models/account.rb'

      @diff = Brakeman.compare(app_path: app_dir,
                               parallel_checks: false,
                               previous_results_json: report_file)
    end

    assert_fixed 7
    assert_new 0
    assert_equal ignored_warnings, @diff[:obsolete]

    # Man is obsolete!
    # Our world, obsolete!
  end
end
