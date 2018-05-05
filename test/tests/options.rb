require_relative '../test'
require 'brakeman/options'

class BrakemanOptionsTest < Minitest::Test
  EASY_OPTION_INPUTS = {
    :exit_on_warn           => "-z",
    :exit_on_error          => "--exit-on-error",
    :rails3                 => "-3",
    :run_all_checks         => "-A",
    :assume_all_routes      => "-a",
    :escape_html            => "-e",
    :ignore_model_output   => "--ignore-model-output",
    :ignore_attr_protected  => "--ignore-protected",
    :interprocedural        => "--interprocedural",
    :ignore_ifs             => "--no-branching",
    :skip_libs              => "--skip-libs",
    :debug                  => "-d",
    :interactive_ignore     => "-I",
    :report_routes          => "-m",
    :absolute_paths         => "--absolute-paths",
    :list_checks            => "-k",
    :list_optional_checks   => "--optional-checks",
    :show_version           => "-v",
    :show_help              => "-h",
    :force_scan             => "--force-scan",
    :ensure_latest          => "--ensure-latest",
    :allow_check_paths_in_config => "--allow-check-paths-in-config",
    :pager                  => "--pager",
  }

  ALT_OPTION_INPUTS = {
    :exit_on_warn           => "--exit-on-warn",
    :rails3                 => "--rails3",
    :run_all_checks         => "--run-all-checks",
    :escape_html            => "--escape-html",
    :debug                  => "--debug",
    :interactive_ignore     => "--interactive-ignore",
    :report_routes          => "--routes",
    :show_version           => "--version",
    :show_help              => "--help"
  }

  def test_easy_options
    EASY_OPTION_INPUTS.each_pair do |key, value|
      options = setup_options_from_input(value)
      assert options[key], "Expected #{key} to be #{!!value}."
    end
  end

  def test_alt_easy_options
    ALT_OPTION_INPUTS.each_pair do |key, value|
      options = setup_options_from_input(value)
      assert options[key], "Expected #{key} to be #{!!value}."
    end
  end

  def test_assume_routes_option
    options = setup_options_from_input("-a")
    assert options[:assume_all_routes]

    options = setup_options_from_input("--assume-routes")
    assert options[:assume_all_routes]

    options = setup_options_from_input("--no-assume-routes")
    assert !options[:assume_all_routes]
  end

  def test_no_exit_on_warn
    options = setup_options_from_input("--exit-on-warn")
    assert options[:exit_on_warn]

    options = setup_options_from_input("--no-exit-on-warn")
    assert !options[:exit_on_warn]
  end

  def test_faster_options
    options = setup_options_from_input("--faster")
    assert options[:ignore_ifs] && options[:skip_libs]
  end

  def test_index_libs_option
    options = setup_options_from_input("--index-libs")
    assert options[:index_libs]

    options = setup_options_from_input("--no-index-libs")
    assert !options[:index_libs]
  end

  def test_limit_options
    options = setup_options_from_input("--branch-limit", "17")
    assert_equal 17, options[:branch_limit]
  end

  def test_no_threads_option
    options = setup_options_from_input("-n").merge!({
      :quiet => true,
      :app_path => "#{TEST_PATH}/apps/rails4"})

    assert !options[:parallel_checks]
  end

  def test_path_option
    options = setup_options_from_input("--path", "#{TEST_PATH}/app/rails4")
    assert_equal "#{TEST_PATH}/app/rails4", options[:app_path]

    options = setup_options_from_input("-p", "#{TEST_PATH}/app/rails4")
    assert_equal "#{TEST_PATH}/app/rails4", options[:app_path]
  end

  def test_progress_option
    options = setup_options_from_input("--progress")
    assert options[:report_progress]

    options = setup_options_from_input("--no-progress")
    assert !options[:report_progress]
  end

  def test_parser_timeout_option
    options = setup_options_from_input("--parser-timeout", "1000")
    assert_equal 1000, options[:parser_timeout]
  end

  def test_quiet_option
    options = setup_options_from_input("-q")
    assert options[:quiet]

    options = setup_options_from_input("--quiet")
    assert options[:quiet]

    options = setup_options_from_input("--no-quiet")
    assert !options[:quiet]
  end

  def test_rails_4_option
    options = setup_options_from_input("-4")
    assert options[:rails4] && options[:rails3]

    options = setup_options_from_input("--rails4")
    assert options[:rails4] && options[:rails3]
  end

  def test_safe_methods_option
    options = setup_options_from_input("--safe-methods", "test_method2,test_method1,test_method2")
    assert_equal Set[:test_method1, :test_method2], options[:safe_methods]

    options = setup_options_from_input("-s", "test_method2,test_method1,test_method2")
    assert_equal Set[:test_method1, :test_method2], options[:safe_methods]
  end

  def test__url_safe_option
    options = setup_options_from_input("--url-safe-methods", "test_method2,test_method1,test_method2")
    assert_equal Set[:test_method1, :test_method2], options[:url_safe_methods]
  end

  def test__skip_file_option
    options = setup_options_from_input("--skip-files", "file1.rb,file2.rb,file3.js,file2.rb")
    assert_equal Set["file1.rb", "file2.rb", "file3.js"], options[:skip_files]
  end

  def test_only_files_option
    options = setup_options_from_input("--only-files", "file1.rb,file2.rb,file3.js,file2.rb")
    assert_equal Set["file1.rb", "file2.rb", "file3.js"], options[:only_files]
  end

  def test_add_lib_paths_option
    options = setup_options_from_input("--add-libs-path", "../tests/,/badStuff/hackable,/etc/junk,../tests/")
    assert_equal Set["../tests/", "/badStuff/hackable", "/etc/junk"], options[:additional_libs_path]
  end

  def test_run_checks_option
    options = setup_options_from_input("-t", "CheckSelectTag,CheckSelectVulnerability,CheckSend,CheckSelectTag,I18nXSS")
    assert_equal Set["CheckSelectTag", "CheckSelectVulnerability", "CheckSend", "CheckI18nXSS"], options[:run_checks]

    options = setup_options_from_input("--test", "CheckSelectTag,CheckSelectVulnerability,CheckSend,CheckSelectTag,I18nXSS")
    assert_equal Set["CheckSelectTag", "CheckSelectVulnerability", "CheckSend", "CheckI18nXSS"], options[:run_checks]
  end

  def test_skip_checks_option
    options = setup_options_from_input("-x", "CheckSelectTag,CheckSelectVulnerability,CheckSend,CheckSelectTag,I18nXSS")
    assert_equal Set["CheckSelectTag", "CheckSelectVulnerability", "CheckSend", "CheckI18nXSS"], options[:skip_checks]

    options = setup_options_from_input("--except", "CheckSelectTag,CheckSelectVulnerability,CheckSend,CheckSelectTag,I18nXSS")
    assert_equal Set["CheckSelectTag", "CheckSelectVulnerability", "CheckSend", "CheckI18nXSS"], options[:skip_checks]
  end

  def test_add_checks_paths_option
    options = setup_options_from_input("--add-checks-path", "../addl_tests/")
    local_path = File.expand_path('../addl_tests/')
    assert_equal Set["#{local_path}"], options[:additional_checks_path]
  end

  def test_format_options
    format_options = {
      pdf: :to_pdf,
      text: :to_s,
      html: :to_html,
      csv: :to_csv,
      tabs: :to_tabs,
      json: :to_json,
      markdown: :to_markdown,
      codeclimate: :to_codeclimate,
      cc: :to_cc,
      plain: :to_plain
    }

    format_options.each_pair do |key, value|
      options = setup_options_from_input("-f", "#{key}")
      assert_equal value, options[:output_format]
    end

    format_options.each_pair do |key, value|
      options = setup_options_from_input("--format", "#{key}")
      assert_equal value, options[:output_format]
    end
  end

  def test_CSS_file_option
    options = setup_options_from_input("--css-file", "../test.css")
    local_path = File.expand_path('../test.css')
    assert_equal local_path, options[:html_style]
  end

  def test_ignore_file_option
    options = setup_options_from_input("-i", "dont_warn_for_these.rb")
    assert_equal "dont_warn_for_these.rb", options[:ignore_file]

    options = setup_options_from_input("--ignore-config", "dont_warn_for_these.rb")
    assert_equal "dont_warn_for_these.rb", options[:ignore_file]
  end

  def test_combine_warnings_option
    options = setup_options_from_input("--combine-locations")
    assert options[:combine_locations]

    options = setup_options_from_input("--no-combine-locations")
    assert !options[:combine_locations]
  end

  def test_report_direct_option
    options = setup_options_from_input("-r")
    assert !options[:check_arguments]

    options = setup_options_from_input("--report-direct")
    assert !options[:check_arguments]
  end

  def test_highlight_option
    options = setup_options_from_input("--highlights")
    assert options[:highlight_user_input]

    options = setup_options_from_input("--no-highlights")
    assert !options[:highlight_user_input]
  end

  def test_message_length_limit_option
    options = setup_options_from_input("--message-limit", "17")
    assert_equal 17, options[:message_limit]
  end

  def test_table_width_option
    options = setup_options_from_input("--table-width", "1717")
    assert_equal 1717, options[:table_width]
  end

  def test_output_file_options
    options = setup_options_from_input("-o", "output.rb")
    assert_equal ["output.rb"], options[:output_files]

    options = setup_options_from_input("--output", "output1.rb,output2.rb")
    assert_equal ["output1.rb,output2.rb"], options[:output_files]
  end

  def test_output_color_option
    options = setup_options_from_input("--color")
    assert_equal :force, options[:output_color]

    options = setup_options_from_input("--no-color")
    assert_equal false, options[:output_color]
  end

  def test_sperate_models_option
    options = setup_options_from_input("--separate-models")
    assert !options[:collapse_mass_assignment]

    options = setup_options_from_input("--no-separate-models")
    assert options[:collapse_mass_assignment]
  end

  def test_github_repo_option
    options = setup_options_from_input("--github-repo", "presidentbeef/brakeman")
    assert_equal "presidentbeef/brakeman", options[:github_repo]
  end

  def test_min_confidence_option
    options = setup_options_from_input("-w", "2")
    assert_equal 1, options[:min_confidence]

    options = setup_options_from_input("--confidence", "1")
    assert_equal 2, options[:min_confidence]
  end

  def test_compare_file_options
    options = setup_options_from_input("--compare", "past_flunks.json")
    compare_file = File.expand_path("past_flunks.json")
    assert_equal compare_file, options[:previous_results_json]
  end

  def test_compare_file_and_output_options
    options = setup_options_from_input("-o", "output.json", "--compare", "output.json")
    assert_equal "output.json", options[:comparison_output_file]
  end

  def test_config_file_options
    options = setup_options_from_input("--config-file", "config.rb")
    config_file = File.expand_path("config.rb")
    assert_equal config_file, options[:config_file]

    options = setup_options_from_input("-c", "config.rb")
    assert_equal config_file, options[:config_file]
  end

  def test_create_config_file_options
    options = setup_options_from_input("--create-config", "config.rb")
    assert_equal "config.rb", options[:create_config]

    options = setup_options_from_input("-C")
    assert options[:create_config]
  end

  def test_summary_options
    options = setup_options_from_input("--summary")

    assert_equal :summary_only, options[:summary_only]

    options = setup_options_from_input("--no-summary")
    assert_equal :no_summary, options[:summary_only]
  end

  private

  def setup_options_from_input(*args)
    options, _ = Brakeman::Options.parse(args)
    options
  end
end
