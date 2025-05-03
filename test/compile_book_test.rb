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
    FileUtils.remove_entry(@tmp)
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

  def test_clean_build_dir_removes_directory
    build = File.join(@tmp, 'build')
    FileUtils.mkdir_p(build)
    File.write(File.join(build, 'foo'), 'bar')
    cb = EpubTools::CompileBook.new(
      title: @title,
      author: @author,
      source_dir: @source,
      build_dir: build
    )

    assert Dir.exist?(build)
    cb.send(:clean_build_dir)

    refute Dir.exist?(build)
  end

  def test_prepare_dirs_creates_xhtml_and_chapters_directories
    build = File.join(@tmp, 'build')
    cb = EpubTools::CompileBook.new(
      title: @title,
      author: @author,
      source_dir: @source,
      build_dir: build
    )
    cb.send(:prepare_dirs)
    xhtml_dir = cb.send(:xhtml_dir)
    chapters_dir = cb.send(:chapters_dir)

    assert Dir.exist?(xhtml_dir)
    assert Dir.exist?(chapters_dir)
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

  def test_validate_sequence_raises_when_no_chapters
    cb = EpubTools::CompileBook.new(
      title: @title,
      author: @author,
      source_dir: @source,
      build_dir: @tmp
    )
    FileUtils.mkdir_p(cb.send(:chapters_dir))
    err = assert_raises(RuntimeError) { cb.send(:validate_sequence) }
    assert_match(/No chapter files found/, err.message)
  end

  def test_validate_sequence_raises_on_missing_chapters
    build = File.join(@tmp, 'build')
    cb = EpubTools::CompileBook.new(
      title: @title,
      author: @author,
      source_dir: @source,
      build_dir: build
    )
    chapters = cb.send(:chapters_dir)
    FileUtils.mkdir_p(chapters)
    File.write(File.join(chapters, 'chap_1.xhtml'), '')
    File.write(File.join(chapters, 'chap_3.xhtml'), '')
    err = assert_raises(RuntimeError) { cb.send(:validate_sequence) }
    assert_match(/Missing chapter numbers: 2/, err.message)
  end

  def test_validate_sequence_succeeds_on_complete_sequence
    build = File.join(@tmp, 'build')
    cb = EpubTools::CompileBook.new(
      title: @title,
      author: @author,
      source_dir: @source,
      build_dir: build
    )
    chapters = cb.send(:chapters_dir)
    FileUtils.mkdir_p(chapters)
    File.write(File.join(chapters, 'chap_1.xhtml'), '')
    File.write(File.join(chapters, 'chap_2.xhtml'), '')
    File.write(File.join(chapters, 'chap_3.xhtml'), '')

    assert_nil cb.send(:validate_sequence)
  end

  def test_run_calls_all_steps_in_order
    cb = EpubTools::CompileBook.new(
      title: @title,
      author: @author,
      source_dir: @source,
      build_dir: @tmp,
      output_file: 'o.epub'
    )
    seq = []
    cb.define_singleton_method(:clean_build_dir)   { seq << :clean }
    cb.define_singleton_method(:prepare_dirs)      { seq << :prepare }
    cb.define_singleton_method(:extract_xhtmls)    { seq << :extract }
    cb.define_singleton_method(:split_xhtmls)      { seq << :split }
    cb.define_singleton_method(:validate_sequence)  { seq << :validate }
    cb.define_singleton_method(:initialize_epub)    { seq << :init }
    cb.define_singleton_method(:add_chapters)      { seq << :add }
    cb.define_singleton_method(:pack_epub)         { seq << :pack }
    cb.define_singleton_method(:log)               { |msg| seq << [:log, msg] }
    cb.run
    expected = [
      :clean, :prepare, :extract, :split,
      :validate, :init, :add, :pack,
      [:log, /Done\. Output EPUB: .*o\.epub/],
      :clean
    ]

    assert_equal expected[0..7], seq[0..7]
    assert_kind_of Array, seq[8]
    assert_equal :log, seq[8][0]
    assert_match expected[8][1], seq[8][1]
    assert_equal expected[9], seq[9]
  end
end
