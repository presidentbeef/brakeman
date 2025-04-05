require_relative '../test'
require 'brakeman/commandline'
require 'tempfile'

class CLExit < StandardError
  attr_reader :exit_code

  def initialize exit_code, message
    super message

    @exit_code = exit_code
  end
end

class TestCommandline < Brakeman::Commandline
  def self.quit exit_code = 0, message = nil
    raise CLExit.new(exit_code, message)
  end
end

class CommandlineTests < Minitest::Test

  # Helper assertions

  def assert_exit exit_code = 0, message = nil
    begin
      yield
    rescue CLExit => e
      assert_equal exit_code, e.exit_code
      assert_equal message, e.message if message
    else
      assert_equal exit_code, 0
    end
  end

  def assert_stdout message, exit_code = 0
    assert_output message, "" do
      assert_exit exit_code do
        yield
      end
    end
  end

  def assert_stderr message, exit_code = 0
    assert_output "", message do
      assert_exit exit_code do
        yield
      end
    end
  end

  # Helpers

  def cl_with_options *opts
    TestCommandline.start(*TestCommandline.parse_options(opts))
  end

  def scan_app *opts
    opts << "#{TEST_PATH}/apps/rails4"
    capture_io do
      cl_with_options(*opts)
    end
  end

  def setup
    Brakeman.debug = false
    Brakeman.quiet = false
  end

  # Tests

  def test_nonexistent_scan_path
    assert_exit Brakeman::No_App_Found_Exit_Code do
      cl_with_options "/fake_brakeman_test_path"
    end
  end

  def test_default_scan_path
    options = {}

    TestCommandline.set_options options

    assert_equal ".", options[:app_path]
  end

  def test_list_checks
    assert_stderr(/\AAvailable Checks:/) do
      cl_with_options "--checks"
    end
  end

  def test_bad_options
    assert_stderr(/\Ainvalid option: --not-a-real-option\nPlease see `brakeman --help`/, -1) do
      cl_with_options "--not-a-real-option"
    end
  end

  def test_version
    assert_stdout "brakeman #{Brakeman::Version}\n" do
      cl_with_options "-v"
    end
  end

  def test_empty_config
    empty_config = "--- {}\n"

    assert_stderr empty_config do
      cl_with_options "-C"
    end
  end

  def test_show_help
    assert_stdout(/\AUsage: brakeman \[options\] rails\/root\/path/) do
      assert_exit do
        cl_with_options "--help"
      end
    end
  end

  def test_exit_on_warn_default
    assert_exit Brakeman::Warnings_Found_Exit_Code do
      scan_app
    end
  end

  def test_no_exit_on_warn
    assert_exit do
      scan_app "--no-exit-on-warn"
    end
  end

  def test_exit_on_warn_no_warnings
    assert_exit do
      scan_app "-t", "None"
    end
  end

  # Assert default when using `--show-ignored` flag.
  def test_show_ignored_warnings
    assert_exit Brakeman::Warnings_Found_Exit_Code do
      scan_app "--show-ignored"
    end
  end

  def test_compare_deactivates_ensure_ignore_notes
    opts, = Brakeman::Commandline.parse_options [
      '--ensure-ignore-notes',
      '--compare', 'foo.json',
    ]
    assert_equal false, opts[:ensure_ignore_notes]
  end

  def test_ensure_ignore_notes
    ignore_file_missing_notes = Tempfile.new('brakeman.ignore')
    ignore_file_missing_notes.write IGNORE_WITH_MISSING_NOTES_JSON
    ignore_file_missing_notes.close

    assert_exit Brakeman::Empty_Ignore_Note_Exit_Code do
      scan_app '--no-exit-on-warn',
               '--ensure-ignore-notes',
               '-i', ignore_file_missing_notes.path.to_s
    end
    ignore_file_missing_notes.unlink

    ignore_file_with_notes = Tempfile.new('brakeman.ignore')
    ignore_file_with_notes.write IGNORE_WITH_NOTES_JSON
    ignore_file_with_notes.close

    assert_exit do
      scan_app '--no-exit-on-warn',
               '--ensure-ignore-notes',
               '-i', ignore_file_with_notes.path.to_s
    end
    ignore_file_with_notes.unlink
  end

  def test_ensure_no_obsolete_ignore_entries
    ignore_file_obsolete_entries = Tempfile.new('brakeman.ignore')
    ignore_file_obsolete_entries.write IGNORE_WITH_OBSOLETE_ENTRIES
    ignore_file_obsolete_entries.close

    assert_exit Brakeman::Obsolete_Ignore_Entries_Exit_Code do
      scan_app '--ensure-no-obsolete-ignore-entries',
               '-i', ignore_file_obsolete_entries.path.to_s,
               '-t', 'None'
    end

    ignore_file_obsolete_entries.unlink
  end

  IGNORE_WITH_MISSING_NOTES_JSON = <<~JSON.freeze
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

  IGNORE_WITH_NOTES_JSON = <<~JSON.freeze
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
          "note": "Note here."
        }
      ],
      "brakeman_version": "4.5.0"
    }
  JSON

  IGNORE_WITH_OBSOLETE_ENTRIES = IGNORE_WITH_NOTES_JSON
end
