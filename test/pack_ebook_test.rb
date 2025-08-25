# frozen_string_literal: true

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
    create_minimal_epub_structure
    output = File.join(@tmp, 'out.epub')
    result = EpubTools::PackEbook.new(input_dir: @epub_dir, output_file: output).run

    verify_return_value(output, result)
    verify_epub_entries(output)
  end

  private

  def create_minimal_epub_structure
    File.write(File.join(@epub_dir, 'mimetype'), 'application/epub+zip')
    FileUtils.mkdir_p(File.join(@epub_dir, 'META-INF'))
    File.write(File.join(@epub_dir, 'META-INF', 'container.xml'), '<container/>')
    FileUtils.mkdir_p(File.join(@epub_dir, 'OEBPS'))
    File.write(File.join(@epub_dir, 'OEBPS', 'title.xhtml'), '<html/>')
  end

  def verify_return_value(expected_output, result)
    assert_equal expected_output, result
    assert_path_exists expected_output, 'Expected output EPUB to exist'
  end

  def verify_epub_entries(output_file)
    entries = extract_zip_entries(output_file)
    verify_mimetype_entry(entries)
    verify_expected_files(entries)
  end

  def extract_zip_entries(output_file)
    entries = []
    Zip::File.open(output_file) do |zip|
      zip.each do |entry|
        entries << { name: entry.name, compression: entry.compression_method }
      end
    end
    entries
  end

  def verify_mimetype_entry(entries)
    assert_equal 'mimetype', entries.first[:name]
    assert_equal 0, entries.first[:compression]
  end

  def verify_expected_files(entries)
    names = entries.map { |e| e[:name] }

    assert_includes names, 'META-INF/container.xml'
    assert_includes names, 'OEBPS/title.xhtml'
  end

  public

  def test_missing_input_dir_raises_error
    assert_raises(ArgumentError) do
      EpubTools::PackEbook.new(input_dir: File.join(@tmp, 'nonexistent'), output_file: 'out.epub').run
    end
  end

  def test_missing_mimetype_raises_error
    # Directory exists but no mimetype file
    dir = File.join(@tmp, 'no_mime')
    Dir.mkdir(dir)
    assert_raises(ArgumentError) do
      EpubTools::PackEbook.new(input_dir: dir, output_file: 'out.epub').run
    end
  end

  def test_default_output_file_name
    # Setup minimal structure with mimetype
    File.write(File.join(@epub_dir, 'mimetype'), 'application/epub+zip')
    # Run without specifying output; default is "<basename>.epub" in parent
    result = EpubTools::PackEbook.new(input_dir: @epub_dir).run
    default_path = File.join(@tmp, 'my_epub.epub')

    # Check return value is the default output path
    assert_equal 'my_epub.epub', result
    assert_path_exists default_path, "Expected default EPUB at \\#{default_path}"
  end
end
