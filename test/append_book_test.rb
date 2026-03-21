# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/epub_tools/append_book'

class AppendBookTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir
    @source = File.join(@tmp, 'src')
    @target = File.join(@tmp, 'target.epub')
    FileUtils.mkdir_p(@source)
    FileUtils.touch(@target)
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def test_initialize_assigns_attributes
    ab = build_append_book(verbose: true)

    assert_equal @source, ab.source_dir
    assert_equal File.expand_path(@target), ab.target_epub
    assert_equal @tmp, ab.build_dir
    assert ab.verbose
  end

  def test_default_build_dir
    ab = EpubTools::AppendBook.new(source_dir: @source, target_epub: @target)

    assert ab.build_dir.end_with?('.epub_tools_build')
  end

  def test_log_outputs_when_verbose
    ab = build_append_book(verbose: true)

    assert_output("hello\n") { ab.send(:log, 'hello') }
  end

  def test_log_silent_when_not_verbose
    ab = build_append_book(verbose: false)

    assert_silent { ab.send(:log, 'hello') }
  end

  def test_detect_conflicts_raises_on_overlap
    ab = build_append_book
    setup_conflict_dirs(ab, new_chapters: [1, 2], existing_chapters: [1])

    error = assert_raises(ArgumentError) { ab.send(:detect_conflicts) }
    assert_match(/chapters 1 already exist/, error.message)
  end

  def test_detect_conflicts_passes_with_no_overlap
    ab = build_append_book
    setup_conflict_dirs(ab, new_chapters: [5], existing_chapters: [1, 2])

    ab.send(:detect_conflicts)
  end

  def test_detect_conflicts_with_half_chapters
    ab = build_append_book
    chapters_dir = File.join(@tmp, 'chapters')
    oebps_dir = File.join(@tmp, 'epub', 'OEBPS')
    FileUtils.mkdir_p([chapters_dir, oebps_dir])

    FileUtils.touch(File.join(chapters_dir, 'chapter_3_5.xhtml'))
    FileUtils.touch(File.join(oebps_dir, 'chapter_3_5.xhtml'))

    workspace = ab.instance_variable_get(:@workspace)
    workspace.instance_variable_set(:@chapters_dir, chapters_dir)
    workspace.instance_variable_set(:@epub_dir, File.join(@tmp, 'epub'))

    error = assert_raises(ArgumentError) { ab.send(:detect_conflicts) }
    assert_match(/3\.5 already exist/, error.message)
  end

  def test_run_completes_workflow
    ab = build_append_book

    def ab.prepare_epub; end
    def ab.extract_xhtmls; end
    def ab.split_xhtmls; end
    def ab.validate_chapters; end
    def ab.before_add_chapters; end
    def ab.add_chapters; end
    def ab.pack_epub; end

    result = ab.run

    assert_equal File.expand_path(@target), result
  end

  def test_backup_creates_bak_file
    File.write(@target, 'epub content')
    ab = build_append_book

    ab.send(:backup_target)

    backup_path = "#{File.expand_path(@target)}.bak"

    assert_path_exists backup_path
    assert_equal 'epub content', File.read(backup_path)
  end

  private

  def build_append_book(verbose: false)
    EpubTools::AppendBook.new(
      source_dir: @source, target_epub: @target,
      build_dir: @tmp, verbose: verbose
    )
  end

  def setup_conflict_dirs(append_book, new_chapters:, existing_chapters:)
    chapters_dir = File.join(@tmp, 'chapters')
    oebps_dir = File.join(@tmp, 'epub', 'OEBPS')
    FileUtils.mkdir_p([chapters_dir, oebps_dir])

    new_chapters.each { |n| FileUtils.touch(File.join(chapters_dir, "chapter_#{n}.xhtml")) }
    existing_chapters.each { |n| FileUtils.touch(File.join(oebps_dir, "chapter_#{n}.xhtml")) }

    workspace = append_book.instance_variable_get(:@workspace)
    workspace.instance_variable_set(:@chapters_dir, chapters_dir)
    workspace.instance_variable_set(:@epub_dir, File.join(@tmp, 'epub'))
  end
end
