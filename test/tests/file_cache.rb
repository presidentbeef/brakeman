require_relative '../test'

require 'securerandom'
require 'brakeman/tracker/file_cache'
require 'brakeman/file_path'
require 'brakeman/file_parser'

class FileCacheTests < Minitest::Test
  def test_basics
    fc = Brakeman::FileCache.new
    af = random_astfile
    other = random_astfile

    fc.add_file af, :controller

    assert fc.controllers[af.path]
    assert fc.cached? af.path
    refute fc.cached? other.path
  end

  def test_valid_type
    fc = Brakeman::FileCache.new

    [:controller, :initializer, :lib, :model, :template].each do |type|
      assert fc.valid_type? type
    end

    refute fc.valid_type? :something_else
  end

  def test_delete
    fc = Brakeman::FileCache.new
    af = random_astfile
    fc.add_file af, :model

    assert fc.cached? af.path
    fc.delete af.path
    refute fc.cached? af.path
  end

  def test_file_path_equivalence
    fc = Brakeman::FileCache.new
    af = random_astfile
    fc.add_file af, :model
    of = Brakeman::FilePath.new(af.path.absolute, af.path.relative)

    assert fc.cached? of
  end

  private

  def random_astfile
    file_name = "file_#{SecureRandom.hex}"
    path = Brakeman::FilePath.new("/tmp/file/#{file_name}", file_name)

    Brakeman::ASTFile.new(path, s(:block))
  end
end
