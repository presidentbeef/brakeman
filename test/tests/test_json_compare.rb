class JSONCompareTests < Test::Unit::TestCase
  include BrakemanTester::DiffHelper

  def setup
    @path = File.expand_path "#{TEST_PATH}/apps/rails3.2"
    @json_path = File.join @path, "report.json"
    File.delete @json_path if File.exist? @json_path
    Brakeman.run :app_path => @path, :output_files => [@json_path]
    @report = MultiJson.load File.read(@json_path)
  end

  def teardown
    File.delete @json_path if File.exist? @json_path
  end

  def update_json
    File.open @json_path, "w" do |f|
      f.puts @report.to_json
    end
  end

  def diff
    @diff = Brakeman.compare :app_path => @path, :previous_results_json => @json_path
  end

  def test_sanity
    diff

    assert_fixed 0
    assert_new 0
  end
end
