# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/epub_tools/compile_book'

class CompileBookTest < Minitest::Test
  def setup
    @tmp    = Dir.mktmpdir
    @title  = 'My Title'
    @author = 'Me'
    @source = File.join(@tmp, 'src')
    FileUtils.mkdir_p(@source)
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def test_default_output_file
    cb = EpubTools::CompileBook.new(
      title: @title,
      author: @author,
      source_dir: @source,
      build_dir: @tmp
    )

    assert_equal 'My_Title.epub', cb.output_file
  end

  def test_override_output_file
    cb = EpubTools::CompileBook.new(
      title: @title,
      author: @author,
      source_dir: @source,
      output_file: 'custom.epub',
      build_dir: @tmp
    )

    assert_equal 'custom.epub', cb.output_file
  end

  def test_default_build_dir
    cb = EpubTools::CompileBook.new(
      title: @title,
      author: @author,
      source_dir: @source
    )

    assert cb.build_dir.end_with?('.epub_tools_build')
  end

  def test_initialize_assigns_attributes
    cb = EpubTools::CompileBook.new(
      title: @title,
      author: @author,
      source_dir: @source,
      cover_image: 'cover.png',
      output_file: 'o.epub',
      build_dir: 'bd',
      verbose: false
    )

    assert_equal @title,       cb.title
    assert_equal @author,      cb.author
    assert_equal @source,      cb.source_dir
    assert_equal 'cover.png',  cb.cover_image
    assert_equal 'o.epub',     cb.output_file
    assert_equal 'bd',         cb.build_dir
    refute cb.verbose
  end

  def test_log_outputs_when_verbose
    cb = EpubTools::CompileBook.new(
      title: @title,
      author: @author,
      source_dir: @source,
      build_dir: @tmp,
      verbose: true
    )
    assert_output("hello\n") { cb.send(:log, 'hello') }
  end

  def test_log_silent_when_not_verbose
    cb = EpubTools::CompileBook.new(
      title: @title,
      author: @author,
      source_dir: @source,
      build_dir: @tmp,
      verbose: false
    )
    assert_silent { cb.send(:log, 'hello') }
  end

  def test_run_completes_workflow
    # Test that run method executes the complete workflow
    cb = EpubTools::CompileBook.new(
      title: @title,
      author: @author,
      source_dir: @source,
      build_dir: @tmp,
      output_file: 'test.epub'
    )

    def cb.extract_xhtmls; end
    def cb.split_xhtmls; end
    def cb.validate_chapters; end
    def cb.before_add_chapters; end
    def cb.add_chapters; end
    def cb.pack_epub; end

    # Should complete without error
    result = cb.run

    assert_equal 'test.epub', result
  end
end
