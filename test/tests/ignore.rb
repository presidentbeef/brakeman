require_relative '../test'
require 'brakeman/report/ignore/config'
require 'tempfile'

class IgnoreConfigTests < Minitest::Test
  attr_reader :config

  def setup
    @config_json = JSON.parse(IGNORE_JSON, symbolize_names: true)

    @config_file = Tempfile.new("brakeman.ignore")
    @config_file.write IGNORE_JSON
    @config_file.close

    @config = make_config
  end

  def make_config file = @config_file.path
    c = Brakeman::IgnoreConfig.new file, report.warnings
    c.read_from_file
    c.filter_ignored
    c
  end

  def teardown
    @config_file.unlink
  end

  def report
    @@report ||= Brakeman.run(File.join(TEST_PATH, "apps", "rails5.2"))
  end

  def test_sanity
    assert_equal @config_json[:ignored_warnings].length, config.ignored_warnings.length
  end

  def test_ignored_warnings
    assert_equal 3, config.ignored_warnings.length
  end

  def test_shown_warnings
    expected = report.warnings.length - config.ignored_warnings.length

    assert_equal expected, config.shown_warnings.length
  end

  def test_unignore_warning
    original_ignored = config.ignored_warnings.dup
    original_shown = config.shown_warnings.dup

    first_ignored = config.ignored_warnings.first

    config.unignore first_ignored
    config.filter_ignored

    refute config.ignored? first_ignored

    assert config.ignored_warnings.length < original_ignored.length
    assert config.shown_warnings.length > original_shown.length

    refute_includes config.ignored_warnings, first_ignored
    assert_includes config.shown_warnings, first_ignored
  end

  def test_ignore_warning
    original_ignored = config.ignored_warnings.dup
    original_shown = config.shown_warnings.dup

    first_warning = config.shown_warnings.first

    config.ignore first_warning
    config.filter_ignored

    assert config.ignored? first_warning

    assert config.ignored_warnings.length > original_ignored.length
    assert config.shown_warnings.length < original_shown.length

    assert_includes config.ignored_warnings, first_warning
    refute_includes config.shown_warnings, first_warning
  end

  def test_add_note
    warning = config.ignored_warnings.first
    note = "Here is an updated note for an ignored warning"

    config.add_note warning, note
    config.save_with_old

    new_config = make_config

    assert note, new_config.note_for(warning)
  end

  def test_note_for_warning
    warning = config.ignored_warnings.find { |w| w.fingerprint == "97ecaa5677c8eadaed09217a704e59092921fab24cc751e05dfb7b167beda2cf" }

    note = config.note_for warning

    refute note.empty?
  end

  def test_note_for_hash
    warning =  { fingerprint: "97ecaa5677c8eadaed09217a704e59092921fab24cc751e05dfb7b167beda2cf" }

    note = config.note_for warning

    refute note.empty?
  end

  def test_empty_note
    warning =  { fingerprint: "3bc375c9cb79d8bcd9e7f1c09a574fa3deeab17f924cf20455cbd4c15e9c66eb" }

    note = config.note_for warning

    assert_equal "", note
  end

  def test_note_missing_for_warning
    warning = config.shown_warnings.first

    note = config.note_for warning

    assert_nil note
  end

  def test_note_missing_for_hash
    warning =  { fingerprint: "not_real" }

    note = config.note_for warning

    assert_nil note
  end

  def test_obsolete
    first_ignored = config.ignored_warnings.first
    known_warnings = config.instance_variable_get(:@new_warnings)
    known_warnings.delete first_ignored

    config.filter_ignored

    assert_equal 1, config.obsolete_fingerprints.length
  end

  def test_prune_obsolete
    first_ignored = config.ignored_warnings.first
    known_warnings = config.instance_variable_get(:@new_warnings)
    known_warnings.delete first_ignored

    config.filter_ignored
    assert_includes config.obsolete_fingerprints, first_ignored.fingerprint

    config.prune_obsolete
    refute_includes config.ignored_warnings, first_ignored

    config.save_with_old
    new_config = make_config

    refute_includes new_config.ignored_warnings, first_ignored
  end

  def test_read_from_nonexistent_file
    make_config("/tmp/not_a_real_file_brakeman.ignore")
  end

  def test_save_new_ignored
    first_ignored = config.ignored_warnings.first
    known_warnings = config.instance_variable_get(:@new_warnings)
    known_warnings.delete first_ignored

    config.filter_ignored
    config.save_with_old

    new_config = make_config

    assert new_config.ignored? first_ignored
  end

  def test_bad_ignore_json_error_message
    file = Tempfile.new("brakeman.ignore2")
    file.write "{[ This is bad json cuz I don't have a closing square bracket, bwahahaha...}"
    file.close
    begin
      c = Brakeman::IgnoreConfig.new file.path, report.warnings
      c.read_from_file
    rescue => e
      # The message should clearly show that there was a problem parsing the json
      assert e.message.index("JSON::ParserError") > 0
      # The message should clearly reference the file containing the bad json
      assert e.message.index(file.path) > 0
    end
  end

  def test_relative_paths_everywhere
    require 'pathname'

    config.shown_warnings.each do |w|
      config.ignore w
    end

    config.filter_ignored
    config.save_with_old

    JSON.parse(File.read(config.file), symbolize_names: true)[:ignored_warnings].each do |w|
      assert_relative w[:file]

      if w[:render_path]
        w[:render_path].each do |loc|
          assert_relative loc[:file]

          if loc[:rendered]
            assert_relative loc[:rendered][:file]
          end
        end
      end
    end
  end

  def test_already_ignored_entries_with_empty_notes
    require 'set'
    assert_equal(
      config.already_ignored_entries_with_empty_notes.map { |i| i[:fingerprint] }.to_set,
      [
        '3bc375c9cb79d8bcd9e7f1c09a574fa3deeab17f924cf20455cbd4c15e9c66eb',
        '006ac5fe3834bf2e73ee51b67eb111066f618be46e391d493c541ea2a906a82f',
      ].to_set
    )
  end

  private

  def assert_relative path
    assert Pathname.new(path).relative?, "#{path} is not relative"
  end
end

IGNORE_JSON = <<JSON
{
  "ignored_warnings": [
    {
      "warning_type": "Remote Code Execution",
      "warning_code": 25,
      "fingerprint": "006ac5fe3834bf2e73ee51b67eb111066f618be46e391d493c541ea2a906a82f",
      "check_name": "Deserialize",
      "message": "`Oj.load` called with parameter value",
      "file": "app/controllers/users_controller.rb",
      "line": 52,
      "link": "https://brakemanscanner.org/docs/warning_types/unsafe_deserialization",
      "code": "Oj.load(params[:json], :mode => :object)",
      "render_path": null,
      "location": {
        "type": "method",
        "class": "UsersController",
        "method": "some_api"
      },
      "user_input": "params[:json]",
      "confidence": "High",
      "note": ""
    },
    {
      "warning_type": "Remote Code Execution",
      "warning_code": 25,
      "fingerprint": "3bc375c9cb79d8bcd9e7f1c09a574fa3deeab17f924cf20455cbd4c15e9c66eb",
      "check_name": "Deserialize",
      "message": "`Oj.object_load` called with parameter value",
      "file": "app/controllers/users_controller.rb",
      "line": 53,
      "link": "https://brakemanscanner.org/docs/warning_types/unsafe_deserialization",
      "code": "Oj.object_load(params[:json], :mode => :strict)",
      "render_path": null,
      "location": {
        "type": "method",
        "class": "UsersController",
        "method": "some_api"
      },
      "user_input": "params[:json]",
      "confidence": "High",
      "note": ""
    },
    {
      "warning_type": "Remote Code Execution",
      "warning_code": 25,
      "fingerprint": "97ecaa5677c8eadaed09217a704e59092921fab24cc751e05dfb7b167beda2cf",
      "check_name": "Deserialize",
      "message": "`Oj.load` called with parameter value",
      "file": "app/controllers/users_controller.rb",
      "line": 51,
      "link": "https://brakemanscanner.org/docs/warning_types/unsafe_deserialization",
      "code": "Oj.load(params[:json])",
      "render_path": null,
      "location": {
        "type": "method",
        "class": "UsersController",
        "method": "some_api"
      },
      "user_input": "params[:json]",
      "confidence": "High",
      "note": "Here's a note!"
    }
  ],
  "brakeman_version": "4.5.0"
}
JSON
