require_relative 'test_helper'
require_relative '../lib/epub_tools/split_chapters'

class SplitChaptersTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir
    @input = File.join(@tmp, 'input.xhtml')
    @out = File.join(@tmp, 'out')
    content = <<~HTML
      <?xml version="1.0"?>
      <html xmlns="http://www.w3.org/1999/xhtml">
        <body>
          <h3>Prologue</h3>
          <p>Intro text</p>
          <p>Chapter 1</p>
          <p>First paragraph</p>
          <p>Chapter 2</p>
          <p>Second paragraph</p>
        </body>
      </html>
    HTML
    File.write(@input, content)
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def test_run_generates_chapter_files
    result = EpubTools::SplitChapters.new(input_file: @input, book_title: 'BookTitle', output_dir: @out,
                                          output_prefix: 'chap').run

    # Check return value is an array of chapter file paths
    assert_instance_of Array, result
    assert_equal 3, result.size

    expected_paths = [
      File.join(@out, 'chap_0.xhtml'),
      File.join(@out, 'chap_1.xhtml'),
      File.join(@out, 'chap_2.xhtml')
    ]

    expected_paths.each do |path|
      assert_includes result, path
      assert_path_exists path, "Expected file #{path} to exist"
    end

    files = Dir.children(@out)

    assert_includes files, 'chap_0.xhtml'
    assert_includes files, 'chap_1.xhtml'
    assert_includes files, 'chap_2.xhtml'

    # Prologue
    prologue = File.read(File.join(@out, 'chap_0.xhtml'))

    assert_includes prologue, '<h1>Prologue</h1>'
    assert_includes prologue, 'Intro text'
    refute_includes prologue, 'Chapter 1'

    # Chapter 1
    ch1 = File.read(File.join(@out, 'chap_1.xhtml'))

    assert_includes ch1, '<h1>Chapter 1</h1>'
    assert_includes ch1, 'First paragraph'
    refute_includes ch1, 'Chapter 2'

    # Chapter 2
    ch2 = File.read(File.join(@out, 'chap_2.xhtml'))

    assert_includes ch2, '<h1>Chapter 2</h1>'
    assert_includes ch2, 'Second paragraph'
  end
end
