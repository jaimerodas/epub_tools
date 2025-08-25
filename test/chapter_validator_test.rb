# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/epub_tools/chapter_validator'

class ChapterValidatorTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir
    @validator = EpubTools::ChapterValidator.new(chapters_dir: @tmp)
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def test_validates_complete_sequence
    create_chapter_files([1, 2, 3, 4, 5])

    assert_silent { @validator.validate }
  end

  def test_raises_on_missing_chapters
    create_chapter_files([1, 2, 4, 5]) # Missing 3

    error = assert_raises(RuntimeError) { @validator.validate }
    assert_match(/Missing chapter numbers: 3/, error.message)
  end

  def test_raises_on_no_chapters
    error = assert_raises(RuntimeError) { @validator.validate }
    assert_match(/No chapter files found/, error.message)
  end

  def test_handles_non_sequential_start
    create_chapter_files([5, 6, 7, 8])

    assert_silent { @validator.validate }
  end

  private

  def create_chapter_files(numbers)
    numbers.each do |num|
      File.write(File.join(@tmp, "chapter_#{num}.xhtml"), '<html></html>')
    end
  end
end
