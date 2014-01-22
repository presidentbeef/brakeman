require 'tempfile'

class BrakemanTests < Test::Unit::TestCase
  def test_exception_on_no_application
    assert_raise Brakeman::NoApplication do
      Brakeman.run "/tmp#{rand}" #better not exist
    end
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
    app_tree = FakeAppTree.new
    @check = Brakeman::BaseCheck.new app_tree, @tracker
  end

  def version_between? version, low, high
    @tracker.config = { :rails_version => version }
    @check.send(:version_between?, low, high)
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
    output_format_tester({:output_format => :others}, [:to_s])
    
    output_format_tester({:output_files => ['xx.html', 'xx.pdf']}, [:to_html, :to_pdf])
    output_format_tester({:output_files => ['xx.pdf', 'xx.json']}, [:to_pdf, :to_json])
    output_format_tester({:output_files => ['xx.json', 'xx.tabs']}, [:to_json, :to_tabs])
    output_format_tester({:output_files => ['xx.tabs', 'xx.csv']}, [:to_tabs, :to_csv])
    output_format_tester({:output_files => ['xx.csv', 'xx.xxx']}, [:to_csv, :to_s])
    output_format_tester({:output_files => ['xx.xx', 'xx.xx']}, [:to_s, :to_s])
    output_format_tester({:output_files => ['xx.html', 'xx.pdf', 'xx.csv', 'xx.tabs', 'xx.json']}, [:to_html, :to_pdf, :to_csv, :to_tabs, :to_json])
  end
end

class GemProcessorTests < Test::Unit::TestCase
  FakeTracker = Struct.new(:config, :options)

  def assert_version version, name, msg = nil
    assert_equal version, @tracker[:config][:gems][name], msg
  end

  def setup 
    @tracker = FakeTracker.new({}, {})
    @gem_processor = Brakeman::GemProcessor.new @tracker 
    @eol_representations = ["\r\n", "\n"] 
    @gem_locks = @eol_representations.inject({}) {|h, eol| 
      h[eol] = "    paperclip (3.2.1)#    erubis (4.3.1)#     rails (3.2.1.rc2)#    simplecov (1.1)#".gsub('#', eol); h 
    }
  end 

  def test_gem_lock_parsing
    @gem_locks.each do |eol, gem_lock|
      @gem_processor.process_gems Sexp.new(:block), gem_lock
      assert_version "4.3.1", :erubis, "Couldn't match gemlock with eol: #{eol}"
      assert_version "3.2.1", :paperclip, "Couldn't match gemlock with eol: #{eol}"
      assert_version "3.2.1.rc2", :rails, "Couldn't match gemlock with eol: #{eol}"  
      assert_version "1.1", :simplecov, "Couldn't match gemlock with eol: #{eol}"
    end 
  end 
end 
