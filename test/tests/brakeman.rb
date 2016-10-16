require 'tempfile'

class BrakemanTests < Minitest::Test
  def test_exception_on_no_application
    assert_raises Brakeman::NoApplication do
      Brakeman.run "/tmp#{rand}" #better not exist
    end
  end

  def test_exception_no_on_no_application_if_forced
    assert_nothing_raised Brakeman::NoApplication do
      Brakeman.run :app_path => "/tmp#{rand}", :force_scan => true #better not exist
    end
  end

  def test_app_tree_root_is_absolute
    require 'brakeman/options'
    relative_path = Pathname.new(File.dirname(__FILE__)).relative_path_from(Pathname.getwd)
    absolute_path = relative_path.realpath.to_s
    input = ["-p", relative_path.to_s]
    options, _ = Brakeman::Options.parse input
    at = Brakeman::AppTree.from_options options

    assert !options[:app_path].start_with?("/")
    assert_equal absolute_path, at.root
    assert_equal File.join(absolute_path, "Gemfile"), at.expand_path("Gemfile")
  end

  def test_relative_path_in_warnings
    relative_path = Pathname.new(File.dirname(__FILE__)).relative_path_from(Pathname.getwd)
    absolute_path = relative_path.realpath.to_s
    input = ["-p", relative_path.to_s]
    options, _ = Brakeman::Options.parse input
    at = Brakeman::AppTree.from_options options


  end

  def test_app_tree_flexible_file_paths
    require 'brakeman/options'
    relative_path = File.expand_path(File.join(TEST_PATH, "/apps/rails4_non_standard_structure/"))
    input = ["-p", relative_path.to_s]
    options, _ = Brakeman::Options.parse input
    at = Brakeman::AppTree.from_options options

    contains_foo_controller = false
    at.controller_paths.each do |path|
      if File.basename(path) == 'foo_controller.rb'
        contains_foo_controller = true
        break
      end
    end

    contains_foo_model = false
    at.model_paths.each do |path|
      if File.basename(path) == 'foo.rb'
        contains_foo_model = true
        break
      end
    end

    contains_foo_view = false
    at.template_paths.each do |path|
      if File.basename(path) == 'foo.html.erb'
        contains_foo_view = true
        break
      end
    end

    assert contains_foo_controller
    assert contains_foo_model
    assert contains_foo_view
  end

  def test_engines_path
    require 'brakeman/options'
    relative_path = File.expand_path(File.join(TEST_PATH, "/apps/rails4_with_engines"))
    input = ["-p", relative_path.to_s,
             "--engines", "engine/user_removal"]
    options, _ = Brakeman::Options.parse input
    at = Brakeman::AppTree.from_options options

    expected_controllers = %w{application_controller.rb removal_controller.rb users_controller.rb}
    basename = Proc.new { |path| File.basename path }
    assert (at.controller_paths.map(&basename) - expected_controllers).empty?
  end
end

class UtilTests < Minitest::Test
  def setup
    @ruby_parser = RubyParser
  end

  def util
    Class.new.extend Brakeman::Util
  end

  def test_cookies?
    assert util.cookies?(@ruby_parser.new.parse 'cookies[:x][:y][:z]')
  end

  def test_params?
    assert util.params?(@ruby_parser.new.parse 'params[:x][:y][:z]')
  end
end

class BaseCheckTests < Minitest::Test
  FakeTracker = Struct.new(:config)
  FakeAppTree = Struct.new(:root)

  def setup
    @tracker = FakeTracker.new
    @tracker.config = Brakeman::Config.new(@tracker)
    app_tree = FakeAppTree.new
    @check = Brakeman::BaseCheck.new app_tree, @tracker
  end

  def version_between? version, low, high
    @tracker.config.rails_version = version
    @check.send(:version_between?, low, high)
  end

  def lts_version? version, low
    if version
      @tracker.config.add_gem :"railslts-version", version, nil, nil
    end
    @check.send(:lts_version?, low)
  end

  def test_version_between
    assert version_between?("2.3.8", "2.3.0", "2.3.8")
    assert version_between?("2.3.8", "2.3.0", "2.3.14")
    assert version_between?("2.3.8", "1.0.0", "5.0.0")
  end

  def test_version_not_between
    assert_equal false, version_between?("3.2.1", "2.0.0", "3.0.0")
    assert_equal false, version_between?("3.2.1", "3.0.0", "3.2.0")
    assert_equal false, version_between?("0.0.0", "3.0.0", "3.2.0")
  end

  def test_version_between_longer
    assert_equal false, version_between?("1.0.1.2", "1.0.0", "1.0.1")
  end

  def test_version_between_pre_release
    assert version_between?("3.2.9.rc2", "3.2.5", "4.0.0")
  end

  def test_lts_version
    @tracker.config.rails_version = "2.3.18"
    assert lts_version? '2.3.18.6', '2.3.18.6'
    assert !lts_version?('2.3.18.1', '2.3.18.6')
    assert !lts_version?(nil, '2.3.18.6')
  end
end

class ConfigTests < Minitest::Test

  def setup
    Brakeman.instance_variable_set(:@quiet, false)
  end

  def test_quiet_option_from_file
    config = Tempfile.new("config")

    config.write <<-YAML.strip
    ---
    :quiet: true
    YAML

    config.close

    options = {
      :config_file => config.path,
      :app_path => "/tmp" #doesn't need to be real
    }

    assert_output "" do
      final_options = Brakeman.set_options(options)

      config.unlink

      assert final_options[:quiet], "Expected quiet option to be true, but was #{final_options[:quiet]}"
    end
  end

  def test_quiet_option_from_commandline
    config = Tempfile.new("config")

    config.write <<-YAML.strip
    ---
    app_path: "/tmp"
    YAML

    config.close

    options = {
      :config_file => config.path,
      :quiet => true,
      :app_path => "/tmp" #doesn't need to be real
    }

    assert_output "" do
      final_options = Brakeman.set_options(options)
    end
  end

  def test_quiet_option_default
    options = {
      :app_path => "/tmp" #doesn't need to be real
    }

    final_options = Brakeman.set_options(options)

    assert final_options[:quiet], "Expected quiet option to be true, but was #{final_options[:quiet]}"
  end

  def test_quiet_command_line_default
    options = {
      :quiet => :command_line,
      :app_path => "/tmp" #doesn't need to be real
    }

    final_options = Brakeman.set_options(options)

    assert_nil final_options[:quiet]
  end

  def test_quiet_inconfig_with_command_line
    config = Tempfile.new("config")

    config.write <<-YAML.strip
    ---
    :quiet: true
    YAML

    config.close

    options = {
      :quiet => :command_line,
      :config_file => config.path,
      :app_path => "#{TEST_PATH}/apps/rails4",
      :run_checks => []
    }

    assert_output "" do
      Brakeman.run options
      config.unlink
    end
  end

  def output_format_tester options, expected_options
    output_formats = Brakeman.get_output_formats(options)

    assert_equal expected_options, output_formats
  end

  def test_output_format
    output_format_tester({}, [:to_s])
    output_format_tester({:output_format => :html}, [:to_html])
    output_format_tester({:output_format => :to_html}, [:to_html])
    output_format_tester({:output_format => :csv}, [:to_csv])
    output_format_tester({:output_format => :to_csv}, [:to_csv])
    output_format_tester({:output_format => :pdf}, [:to_pdf])
    output_format_tester({:output_format => :to_pdf}, [:to_pdf])
    output_format_tester({:output_format => :json}, [:to_json])
    output_format_tester({:output_format => :to_json}, [:to_json])
    output_format_tester({:output_format => :tabs}, [:to_tabs])
    output_format_tester({:output_format => :to_tabs}, [:to_tabs])
    output_format_tester({:output_format => :markdown}, [:to_markdown])
    output_format_tester({:output_format => :to_markdown}, [:to_markdown])
    output_format_tester({:output_format => :others}, [:to_s])

    output_format_tester({:output_files => ['xx.html', 'xx.pdf']}, [:to_html, :to_pdf])
    output_format_tester({:output_files => ['xx.pdf', 'xx.json']}, [:to_pdf, :to_json])
    output_format_tester({:output_files => ['xx.json', 'xx.tabs']}, [:to_json, :to_tabs])
    output_format_tester({:output_files => ['xx.tabs', 'xx.csv']}, [:to_tabs, :to_csv])
    output_format_tester({:output_files => ['xx.csv', 'xx.xxx']}, [:to_csv, :to_s])
    output_format_tester({:output_files => ['xx.md', 'xx.xxx']}, [:to_markdown, :to_s])
    output_format_tester({:output_files => ['xx.xx', 'xx.xx']}, [:to_s, :to_s])
    output_format_tester({:output_files => ['xx.html', 'xx.pdf', 'xx.csv', 'xx.tabs', 'xx.json', 'xx.md']}, [:to_html, :to_pdf, :to_csv, :to_tabs, :to_json, :to_markdown])
  end

  def test_output_format_errors_raised
    options = {:output_format => :to_json, :output_files => ['xx.csv', 'xx.xxx']}
    assert_raises(ArgumentError) { Brakeman.get_output_formats(options) }
  end

  def test_github_options_raises_error
    options = {:github_repo => 'www.test.com', :app_path => "/tmp"}
    assert_raises ArgumentError do
      Brakeman.set_options(options)
    end
  end

  def test_github_options_returns_url
    options = {:github_repo => 'presidentbeef/brakeman', :app_path => "/tmp"}

    final_options = Brakeman.set_options(options)
    assert final_options[:github_url], "https://www.github.com/presidentbeef/brakeman"
  end

  def test_optional_check_options
    options = {:list_optional_checks => true}
    check_list = capture_io {
      Brakeman.list_checks(options)
    }[1]
    Brakeman::Checks.optional_checks.each do |check|
      assert check_list.include? check.to_s.split("::").last
      assert check_list.include? check.description
    end
  end

  def test_default_check_options
    options = {}
    check_list = capture_io {
      Brakeman.list_checks(options)
    }[1]
    Brakeman::Checks.checks.each do |check|
      assert check_list.include? check.to_s.split("::").last
      assert check_list.include? check.description
    end
  end

  def test_dump_config_no_file
    options = {:create_config => true, :test_option => "test"}

    assert_output nil, "---\n:test_option: test\n" do
      Brakeman.dump_config(options)
    end
  end

  def test_dump_config_with_set
    require 'set'
    test_set = Set.new ["test", "test2"]
    options = {:create_config => true, :test_option => test_set}

    assert_output nil, "---\n:test_option:\n- test\n- test2\n" do
      Brakeman.dump_config(options)
    end
  end

  def test_dump_config_with_file
    test_file = "test.cfg"
    options = {:create_config => test_file, :test_option => "test"}

    assert_output nil, "Output configuration to test.cfg\n" do
      Brakeman.dump_config(options)
    end

    file_text = File.read(test_file)
    assert_equal file_text, "---\n:test_option: test\n"
  ensure
    assert File.delete test_file
  end
end

class GemProcessorTests < Minitest::Test
  FakeTracker = Struct.new(:config, :options)

  def assert_version version, name, msg = nil
    assert_equal version, @tracker.config.gem_version(name), msg
  end

  def setup
    @tracker = FakeTracker.new
    @tracker.options = {}
    @tracker.config = Brakeman::Config.new(@tracker)
    @gem_processor = Brakeman::GemProcessor.new @tracker
    @eol_representations = ["\r\n", "\n"]
    @gem_locks = @eol_representations.inject({}) {|h, eol|
      h[eol] = "    paperclip (3.2.1)#    erubis (4.3.1)#     rails (3.2.1.rc2)#    simplecov (1.1)#".gsub('#', eol); h
    }
  end

  def test_gem_lock_parsing
    empty_block = Sexp.new(:block)
    @gem_locks.each do |eol, gem_lock|
      @gem_processor.process_gems :gemfile => { :file => "Gemfile", :src => empty_block}, :gemlock => { :file => "gems.locked", :src => gem_lock }
      assert_version "4.3.1", :erubis, "Couldn't match gemlock with eol: #{eol}"
      assert_version "3.2.1", :paperclip, "Couldn't match gemlock with eol: #{eol}"
      assert_version "3.2.1.rc2", :rails, "Couldn't match gemlock with eol: #{eol}"
      assert_version "1.1", :simplecov, "Couldn't match gemlock with eol: #{eol}"
    end
  end
end
