require_relative '../test'
require 'brakeman/app_tree'
require 'brakeman/file_path'

class FilePathTests < Minitest::Test
  def test_relative_from_app_tree
    at = Brakeman::AppTree.new("/tmp/blah")
    fp = Brakeman::FilePath.from_app_tree at, "thing.rb"

    assert_equal "thing.rb", fp.relative
    assert_equal "/tmp/blah/thing.rb", fp.absolute
  end

  def test_absolute_from_app_tree
    at = Brakeman::AppTree.new("/tmp/blah")
    fp = Brakeman::FilePath.from_app_tree at, "/tmp/blah/thing.rb"

    assert_equal "thing.rb", fp.relative
    assert_equal "/tmp/blah/thing.rb", fp.absolute
  end

  def test_from_app_tree_already_file_path
    at = Brakeman::AppTree.new("/tmp/blah")
    fp1 = Brakeman::FilePath.from_app_tree at, "/tmp/blah/thing.rb"
    fp2 = Brakeman::FilePath.from_app_tree at, fp1

    assert_same fp1, fp2
  end

  def test_from_tracker_already_file_path
    at = Brakeman::AppTree.new("/tmp/blah")
    fp1 = at.file_path "/tmp/blah/thing.rb"
    fp2 = at.file_path fp1

    assert_same fp1, fp2
  end

  def test_file_path_to_str
    at = Brakeman::AppTree.new("/tmp/blah")
    fp = Brakeman::FilePath.from_app_tree at, "/tmp/blah/thing.rb"

    assert_equal "/tmp/blah/thing.rb", fp.to_str
    assert_equal "/tmp/blah/thing.rb", "#{fp}"
  end

  def test_file_path_equality
    at = Brakeman::AppTree.new("/tmp/blah")
    fp1 = Brakeman::FilePath.from_app_tree at, "/tmp/blah/thing.rb"
    fp2 = Brakeman::FilePath.from_app_tree at, "thing.rb"
    fp3 = Brakeman::FilePath.from_app_tree at, "thing2.rb"

    assert_equal fp1, fp2
    assert_equal fp2, fp1

    refute_equal fp1, fp3
    refute_equal fp3, fp2

    assert_includes [fp1], fp2
    assert_includes [fp2], fp1

    refute_includes [fp1], fp3
    refute_includes [fp3], fp2
  end


  def test_file_path_equality_not_cached
    fp1 = Brakeman::FilePath.new("/tmp/blah/thing.rb", "thing.rb")
    fp2 = Brakeman::FilePath.new("/tmp/blah/thing.rb", "thing.rb")

    assert_equal fp1, fp2
    assert_equal fp2, fp1
    assert_equal fp1.hash, fp2.hash
    assert fp1.eql?(fp2)
    assert fp2.eql?(fp1)

    # Ensure FilePaths used as hash keys are equal
    h = {fp1 => 1}

    assert_equal 1, h[fp1]
    assert_equal 1, h[fp2]
  end

  def test_file_path_cache
    at = Brakeman::AppTree.new("/tmp/blah")
    fp1 = Brakeman::FilePath.from_app_tree at, "/tmp/blah/thing.rb"
    fp2 = Brakeman::FilePath.from_app_tree at, "thing.rb"

    assert_same fp1, fp2
    assert_same fp2, fp1
  end
end
