# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/epub_tools/compile_workspace'

class CompileWorkspaceTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir
    @workspace = EpubTools::CompileWorkspace.new(@tmp)
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def test_initialize_sets_build_dir
    assert_equal @tmp, @workspace.build_dir
  end

  def test_prepare_directories_creates_required_dirs
    @workspace.prepare_directories

    assert Dir.exist?(@workspace.xhtml_dir)
    assert Dir.exist?(@workspace.chapters_dir)
  end

  def test_directory_paths_are_correct
    assert_equal File.join(@tmp, 'xhtml'), @workspace.xhtml_dir
    assert_equal File.join(@tmp, 'chapters'), @workspace.chapters_dir
    assert_equal File.join(@tmp, 'epub'), @workspace.epub_dir
  end

  def test_directory_paths_are_memoized
    # First call creates the path
    path1 = @workspace.xhtml_dir
    # Second call should return the same object
    path2 = @workspace.xhtml_dir

    assert_equal path1, path2
  end

  def test_clean_removes_build_directory
    # Create the directory and some content
    FileUtils.mkdir_p(@tmp)
    test_file = File.join(@tmp, 'test.txt')
    File.write(test_file, 'test content')

    assert Dir.exist?(@tmp)
    assert_path_exists test_file

    @workspace.clean

    refute Dir.exist?(@tmp)
  end
end
