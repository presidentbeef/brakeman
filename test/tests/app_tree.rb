require_relative '../test'
require 'brakeman/app_tree'
require 'fileutils'

class AppTreeTests < Minitest::Test
  def temp_dir_and_file_from_path(relative_path)
    Dir.mktmpdir do |dir|
      file = File.join(dir, relative_path)
      FileUtils.mkdir_p(File.dirname(file))
      FileUtils.touch(file)
      yield dir, file
    end
  end

  def temp_dir_absolute_symlink_and_file_from_path(relative_path)
    Dir.mktmpdir do |dir|
      sibling_dir = File.join(dir, "sibling")
      FileUtils.mkdir_p(sibling_dir)

      target_dir = File.join(dir, "target")
      FileUtils.mkdir_p(target_dir)

      file = File.join(sibling_dir, relative_path)
      FileUtils.mkdir_p(File.dirname(file))
      FileUtils.touch(file)

      symlink = File.join(target_dir, "symlink")
      FileUtils.ln_s(sibling_dir, symlink, force: true)
      yield target_dir, file
    end
  end

  def temp_dir_relative_symlink_and_file_from_path(relative_path)
    Dir.mktmpdir do |dir|
      sibling_dir = File.join(dir, "sibling")
      FileUtils.mkdir_p(sibling_dir)

      target_dir = File.join(dir, "target")
      FileUtils.mkdir_p(target_dir)

      file = File.join(sibling_dir, relative_path)
      FileUtils.mkdir_p(File.dirname(file))
      FileUtils.touch(file)

      symlink = File.join(target_dir, "symlink")
      FileUtils.ln_s("../sibling", symlink, force: true)
      yield target_dir, file
    end
  end

  def test_directory_absolute_symlink_support
    temp_dir_absolute_symlink_and_file_from_path("test.rb") do |dir, file|
      at = Brakeman::AppTree.new(dir, follow_symlinks: true)
      assert_equal [file], at.ruby_file_paths.collect(&:absolute).to_a
    end
  end

  def test_directory_relative_symlink_support
    temp_dir_relative_symlink_and_file_from_path("test.rb") do |dir, file|
      at = Brakeman::AppTree.new(dir, follow_symlinks: true)
      assert_equal [file], at.ruby_file_paths.collect(&:absolute).to_a
    end
  end

  def test_directory_relative_disabled_symlink_support
    temp_dir_relative_symlink_and_file_from_path("test.rb") do |dir, file|
      at = Brakeman::AppTree.new(dir, follow_symlinks: false)
      assert_empty at.ruby_file_paths.collect(&:absolute).to_a
    end
  end

  def test_ruby_file_paths
    temp_dir_and_file_from_path("test.rb") do |dir, file|
      at = Brakeman::AppTree.new(dir)
      assert_equal [file], at.ruby_file_paths.collect(&:absolute).to_a
    end
  end

  def test_ruby_file_paths_skip_vendor_false
    temp_dir_and_file_from_path("vendor/test.rb") do |dir, file|
      at = Brakeman::AppTree.new(dir, :skip_vendor => false)
      assert_equal [file], at.ruby_file_paths.collect(&:absolute).to_a
    end
  end

  def test_ruby_file_paths_skip_vendor_true
    temp_dir_and_file_from_path("vendor/test.rb") do |dir, file|
      at = Brakeman::AppTree.new(dir, :skip_vendor => true)
      assert_equal [], at.ruby_file_paths.collect(&:absolute).to_a
    end
  end

  def test_ruby_file_paths_skip_vendor_true_add_libs_path
    temp_dir_and_file_from_path("vendor/bundle/gems/gem123/lib/test.rb") do |dir, file|
      at = Brakeman::AppTree.new(dir, :skip_vendor => true, :additional_libs_path => ["vendor/bundle/gems/gem123/lib"])
      assert_equal [file], at.ruby_file_paths.collect(&:absolute).to_a
    end
  end

  def test_ruby_file_paths_skip_vendor_true_add_engine_path
    temp_dir_and_file_from_path("vendor/bundle/gems/gem123/test.rb") do |dir, file|
      at = Brakeman::AppTree.new(dir, :skip_vendor => true, :engine_paths => ["vendor/bundle/gems"])
      assert_equal [file], at.ruby_file_paths.collect(&:absolute).to_a
    end
  end

  def test_ruby_file_paths_skip_vendor_true_tests_in_engine_path_still_excluded
    temp_dir_and_file_from_path("vendor/bundle/gems/gem123/test/test.rb") do |dir, file|
      at = Brakeman::AppTree.new(dir, :skip_vendor => true, :engine_paths => ["vendor/bundler/gems"])
      assert_equal [], at.ruby_file_paths.collect(&:absolute).to_a
    end
  end

  def test_ruby_file_paths_add_engine_path
    temp_dir_and_file_from_path("lib/gems/gem123/test.rb") do |dir, file|
      at = Brakeman::AppTree.new(dir, :engine_paths => ["lib/gems"])
      assert_equal [file], at.ruby_file_paths.collect(&:absolute).to_a
    end
  end

  def test_ruby_file_paths_add_libs_path
    temp_dir_and_file_from_path("gem123/lib/test.rb") do |dir, file|
      at = Brakeman::AppTree.new(dir, :additional_libs_path => ["gems/gem123/lib"])
      assert_equal [file], at.ruby_file_paths.collect(&:absolute).to_a
    end
  end

  def test_ruby_file_paths_directory_with_rb_extension
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "test.rb"))

      at = Brakeman::AppTree.new(dir)
      assert_equal [], at.ruby_file_paths.collect(&:absolute).to_a
    end
  end
end
