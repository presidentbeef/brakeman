require 'tempfile'

class BrakemanTests < Test::Unit::TestCase
  def test_exception_on_no_application
    assert_raise Brakeman::NoApplication do
      Brakeman.run "/tmp#{rand}" #better not exist
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
end

class UtilTests < Test::Unit::TestCase
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

class BaseCheckTests < Test::Unit::TestCase
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

class ConfigTests < Test::Unit::TestCase

  def setup
    Brakeman.instance_variable_set(:@quiet, false)
  end

  # method from test-unit: http://test-unit.rubyforge.org/test-unit/en/Test/Unit/Util/Output.html#capture_output-instance_method
  def capture_output
    require 'stringio'

    output = StringIO.new
    error = StringIO.new
    stdout_save, stderr_save = $stdout, $stderr
    $stdout, $stderr = output, error
    begin
      yield
      [output.string, error.string]
    ensure
      $stdout, $stderr = stdout_save, stderr_save
    end
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

    assert_equal "", capture_output {
      final_options = Brakeman.set_options(options)

      config.unlink

      assert final_options[:quiet], "Expected quiet option to be true, but was #{final_options[:quiet]}"
    }[1]
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

    assert_equal "", capture_output {
      final_options = Brakeman.set_options(options)
    }[1]
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

    assert_equal "", capture_output {
      Brakeman.run options
      config.unlink
    }[1]
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
    assert_raises("ArgumentError: Cannot specify output format if multiple output files specified") {Brakeman.get_output_formats(options)}
  end

  def test_github_options_raises_error
    config = Tempfile.new("config")

    config.write <<-YAML.strip
    ---
    :quiet: true
    YAML

    config.close
    options = {:github_repo => 'www.test.com', :app_path => "/tmp"}
    assert_raise ArgumentError do
      Brakeman.set_options(options)
    end
  end

  def test_github_options_returns_url
    # config = Tempfile.new("config")

    # config.write <<-YAML.strip
    # ---
    # :quiet: true
    # YAML

    # config.close
    options = {:github_repo => 'presidentbeef/brakeman', :app_path => "/tmp"}

    final_options = Brakeman.set_options(options)
    assert final_options[:github_url], "https://www.github.com/presidentbeef/brakeman"
  end

  def test_optional_check_options
    options = {:list_optional_checks => true}
    assert_equal "Optional Checks:\n------------------------------\nCheckSymbolDoS                Checks for symbol denial of service\nCheckUnscopedFind             Check for unscoped ActiveRecord queries\nCheckWeakHash                 Checks for use of weak hashes like MD5\n", capture_output {
      final_options = Brakeman.list_checks(options)
    }[1]
  end

  def test_default_check_options
    options = {}
    checks_results = "Available Checks:\n------------------------------\nCheckBasicAuth                Checks for the use of http_basic_authenticate_with\nCheckCrossSiteScripting       Checks for unescaped output in views\nCheckContentTag               Checks for XSS in calls to content_tag\nCheckCreateWith               Checks for strong params bypass in CVE-2014-3514\nCheckDefaultRoutes            Checks for default routes\nCheckDeserialize              Checks for unsafe deserialization of objects\nCheckDetailedExceptions       Checks for information disclosure displayed via detailed exceptions\nCheckDigestDoS                Checks for digest authentication DoS vulnerability\nCheckEscapeFunction           Checks for versions before 2.3.14 which have a vulnerable escape method\nCheckEvaluation               Searches for evaluation of user input\nCheckExecute                  Finds instances of possible command injection\nCheckFileAccess               Finds possible file access using user input\nCheckFileDisclosure           Checks for versions with file existence disclosure vulnerability\nCheckFilterSkipping           Checks for versions 3.0-3.0.9 which had a vulnerability in filters\nCheckForgerySetting           Verifies that protect_from_forgery is enabled in ApplicationController\nCheckHeaderDoS                Checks for header DoS (CVE-2013-6414)\nCheckI18nXSS                  Checks for i18n XSS (CVE-2013-4491)\nCheckJRubyXML                 Checks for versions with JRuby XML parsing backend\nCheckJSONEncoding             Checks for missing JSON encoding (CVE-2015-3226)\nCheckJSONParsing              Checks for JSON parsing vulnerabilities CVE-2013-0333 and CVE-2013-0269\nCheckLinkTo                   Checks for XSS in link_to in versions before 3.0\nCheckLinkToHref               Checks to see if values used for hrefs are sanitized using a :url_safe_method to protect against javascript:/data: XSS\nCheckMailTo                   Checks for mail_to XSS vulnerability in certain versions\nCheckMassAssignment           Finds instances of mass assignment\nCheckModelAttrAccessible      Reports models which have dangerous attributes defined under the attr_accessible whitelist.\nCheckModelAttributes          Reports models which do not use attr_restricted and warns on models that use attr_protected\nCheckModelSerialize           Report uses of serialize in versions vulnerable to CVE-2013-0277\nCheckNestedAttributes         Checks for nested attributes vulnerability in Rails 2.3.9 and 3.0.0\nCheckNumberToCurrency         Checks for number helpers XSS vulnerabilities in certain versions\nCheckQuoteTableName           Checks for quote_table_name vulnerability in versions before 2.3.14 and 3.0.10\nCheckRedirect                 Looks for calls to redirect_to with user input as arguments\nCheckRegexDoS                 Searches regexes including user input\nCheckRender                   Finds calls to render that might allow file access\nCheckRenderDoS                Warn about denial of service with render :text (CVE-2014-0082)\nCheckRenderInline             Checks for cross site scripting in render calls\nCheckResponseSplitting        Report response splitting in Rails 2.3.0 - 2.3.13\nCheckSafeBufferManipulation   Check for Rails versions with SafeBuffer bug\nCheckSanitizeMethods          Checks for versions with vulnerable sanitize and sanitize_css\nCheckSelectTag                Looks for unsafe uses of select_tag() in some versions of Rails 3.x\nCheckSelectVulnerability      Looks for unsafe uses of select() helper\nCheckSend                     Check for unsafe use of Object#send\nCheckSendFile                 Check for user input in uses of send_file\nCheckSessionManipulation      Check for user input in session keys\nCheckSessionSettings          Checks for session key length and http_only settings\nCheckSimpleFormat             Checks for simple_format XSS vulnerability (CVE-2013-6416) in certain versions\nCheckSingleQuotes             Check for versions which do not escape single quotes (CVE-2012-3464)\nCheckSkipBeforeFilter         Warn when skipping CSRF or authentication checks by default\nCheckSQL                      Check for SQL injection\nCheckSQLCVEs                  Checks for several SQL CVEs\nCheckSSLVerify                Checks for OpenSSL::SSL::VERIFY_NONE\nCheckStripTags                Report strip_tags vulnerabilities CVE-2011-2931 and CVE-2012-3465\nCheckSymbolDoSCVE             Checks for versions with ActiveRecord symbol denial of service vulnerability\nCheckTranslateBug             Report XSS vulnerability in translate helper\nCheckUnsafeReflection         Checks for unsafe reflection\nCheckValidationRegex          Report uses of validates_format_of with improper anchors\nCheckWithoutProtection        Check for mass assignment using without_protection\nCheckXMLDoS                   Checks for XML denial of service (CVE-2015-3227)\nCheckYAMLParsing              Checks for YAML parsing vulnerabilities (CVE-2013-0156)\nCheckSymbolDoS                Checks for symbol denial of service\nCheckUnscopedFind             Check for unscoped ActiveRecord queries\nCheckWeakHash                 Checks for use of weak hashes like MD5\n"
    assert_equal checks_results, capture_output {
      final_options = Brakeman.list_checks(options)
    }[1]
  end

end

class GemProcessorTests < Test::Unit::TestCase
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
