require 'fileutils'
require 'tmpdir'

class RakeTaskTests < Test::Unit::TestCase
  def setup
    # Brakeman is noisy on errors
    @old_stderr = $stderr.dup
    $stderr.reopen("/dev/null", "w")
  end

  def cleanup
    $stderr = old_stderr
  end

  def in_temp_app
    Dir.mktmpdir do |dir|
      begin
        FileUtils.cp_r "#{TEST_PATH}/apps/rails3.2/.", dir

        @rake_task = "#{dir}/lib/tasks/brakeman.rake"
        @rakefile = "#{dir}/Rakefile"

        current_dir = FileUtils.pwd
        FileUtils.cd dir

        yield dir

      ensure
        FileUtils.cd current_dir
      end
    end
  end

  def test_create_rake_task
    in_temp_app do
      assert_nothing_raised SystemExit do
        Brakeman.install_rake_task
      end

      assert File.exist? @rake_task
    end
  end

  def test_rake_task_exists
    in_temp_app do
      assert_nothing_raised Brakeman::RakeInstallError do
        Brakeman.install_rake_task
      end

      assert_raise Brakeman::RakeInstallError do
        Brakeman.install_rake_task
      end
    end
  end

  def test_rake_no_Rakefile
    in_temp_app do
      File.delete @rakefile

      assert_raise Brakeman::RakeInstallError do
        Brakeman.install_rake_task
      end
    end
  end
end
