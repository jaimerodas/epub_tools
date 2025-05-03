require_relative 'test_helper'
require_relative '../lib/epub_tools/unpack_ebook'
require 'zip'

class UnpackEbookTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir
    # Build a minimal EPUB directory for zipping
    @build_dir = File.join(@tmp, 'build')
    FileUtils.mkdir_p(File.join(@build_dir, 'META-INF'))
    FileUtils.mkdir_p(File.join(@build_dir, 'OEBPS'))
    File.write(File.join(@build_dir, 'mimetype'), 'application/epub+zip')
    File.write(File.join(@build_dir, 'META-INF', 'container.xml'), '<container/>')
    File.write(File.join(@build_dir, 'OEBPS', 'title.xhtml'), '<html/>')

    # Create .epub zip file
    @epub_file = File.join(@tmp, 'test.epub')
    # Create .epub zip file with absolute src paths to avoid cwd issues
    Zip::File.open(@epub_file, Zip::File::CREATE) do |zip|
      # Add mimetype first, uncompressed
      mime_src = File.join(@build_dir, 'mimetype')
      zip.add_stored('mimetype', mime_src)
      # Add directories and files
      Dir.glob(File.join(@build_dir, '**', '*'), File::FNM_DOTMATCH).sort.each do |src_path|
        rel_path = src_path.sub(%r{^#{Regexp.escape(@build_dir)}/?}, '')
        next if rel_path.empty? || rel_path == 'mimetype'

        if File.directory?(src_path)
          zip.mkdir(rel_path)
        else
          zip.add(rel_path, src_path)
        end
      end
    end

    @dest_dir = File.join(@tmp, 'output')
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def test_run_extracts_all_entries
    result = EpubTools::UnpackEbook.new(epub_file: @epub_file, output_dir: @dest_dir).run

    # Check return value is the output directory path
    assert_equal @dest_dir, result

    # Check extracted files
    assert Dir.exist?(@dest_dir)
    assert_equal 'application/epub+zip', File.read(File.join(@dest_dir, 'mimetype'))
    assert_path_exists File.join(@dest_dir, 'META-INF', 'container.xml')
    assert_path_exists File.join(@dest_dir, 'OEBPS', 'title.xhtml')
  end

  def test_run_with_default_output_dir
    # Create the test with default output directory
    result = EpubTools::UnpackEbook.new(epub_file: @epub_file).run

    expected_dir = File.join(File.dirname(@epub_file), File.basename(@epub_file, '.epub'))

    assert_equal expected_dir, result
    assert Dir.exist?(expected_dir)
    assert_path_exists File.join(expected_dir, 'mimetype')
  end

  def test_missing_epub_raises_error
    missing = File.join(@tmp, 'nope.epub')
    error = assert_raises(ArgumentError) do
      EpubTools::UnpackEbook.new(epub_file: missing, output_dir: @dest_dir).run
    end
    assert_includes error.message, 'does not exist'
  end
end
