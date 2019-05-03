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

  def test_file_path_to_str
    at = Brakeman::AppTree.new("/tmp/blah")
    fp = Brakeman::FilePath.from_app_tree at, "/tmp/blah/thing.rb"

    assert_equal "/tmp/blah/thing.rb", fp.to_str
    assert_equal "/tmp/blah/thing.rb", "#{fp}"
  end

  def test_file_path_compare
    at = Brakeman::AppTree.new("/tmp/blah")
    fp1 = Brakeman::FilePath.from_app_tree at, "/tmp/blah/thing.rb"
    fp2 = Brakeman::FilePath.from_app_tree at, "thing.rb"

    assert_equal fp1, fp2
    assert_equal fp2, fp1

    assert_includes [fp1], fp2
    assert_includes [fp2], fp1
  end
end
