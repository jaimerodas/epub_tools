require_relative 'test_helper'
require_relative '../lib/epub_tools/pack_ebook'
require 'zip'

class PackEbookTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir
    @epub_dir = File.join(@tmp, 'my_epub')
    Dir.mkdir(@epub_dir)
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def test_run_creates_epub_with_expected_entries
    # Create minimal EPUB directory
    File.write(File.join(@epub_dir, 'mimetype'), 'application/epub+zip')
    FileUtils.mkdir_p(File.join(@epub_dir, 'META-INF'))
    File.write(File.join(@epub_dir, 'META-INF', 'container.xml'), '<container/>' )
    FileUtils.mkdir_p(File.join(@epub_dir, 'OEBPS'))
    File.write(File.join(@epub_dir, 'OEBPS', 'title.xhtml'), '<html/>' )

    output = File.join(@tmp, 'out.epub')
    EpubTools::PackEbook.new(@epub_dir, output).run

    assert File.exist?(output), 'Expected output EPUB to exist'
    entries = []
    Zip::File.open(output) do |zip|
      zip.each do |entry|
        entries << { name: entry.name, compression: entry.compression_method }
      end
    end

    # First entry should be mimetype, stored without compression
    assert_equal 'mimetype', entries.first[:name]
    assert_equal 0, entries.first[:compression]

    # Check presence of other files
    names = entries.map { |e| e[:name] }
    assert_includes names, 'META-INF/container.xml'
    assert_includes names, 'OEBPS/title.xhtml'
  end

  def test_missing_input_dir_raises_error
    assert_raises(ArgumentError) do
      EpubTools::PackEbook.new(File.join(@tmp, 'nonexistent'), 'out.epub').run
    end
  end

  def test_missing_mimetype_raises_error
    # Directory exists but no mimetype file
    dir = File.join(@tmp, 'no_mime')
    Dir.mkdir(dir)
    assert_raises(ArgumentError) do
      EpubTools::PackEbook.new(dir, 'out.epub').run
    end
  end

  def test_default_output_file_name
    # Setup minimal structure with mimetype
    File.write(File.join(@epub_dir, 'mimetype'), 'application/epub+zip')
    # Run without specifying output; default is "<basename>.epub" in parent
    EpubTools::PackEbook.new(@epub_dir).run
    default_path = File.join(@tmp, 'my_epub.epub')
    assert File.exist?(default_path), "Expected default EPUB at \\#{default_path}"
  end
end
