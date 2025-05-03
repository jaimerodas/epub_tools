require 'yaml'
require_relative 'test_helper'
require_relative '../lib/epub_tools/xhtml_cleaner'

class XHTMLCleanerTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir
    @config = File.join(@tmp, 'config.yaml')
    File.write(@config, { 'italics' => ['itclass'], 'bolds' => ['boldclass'] }.to_yaml)
    @file = File.join(@tmp, 'test.xhtml')
    content = <<~HTML
      <?xml version="1.0" encoding="UTF-8"?>
      <html xmlns="http://www.w3.org/1999/xhtml">
        <body>
          <p><span class="itclass">ItalicsOnly</span></p>
          <p>Keep<span class="plain">This</span></p>
          <p><span class="boldclass">RemoveMe</span></p>
          <hr style="page-break-before:always"/>
          <p class="empty"></p>
        </body>
      </html>
    HTML
    File.write(@file, content)
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def test_cleaner_removes_and_transforms_tags
    result = EpubTools::XHTMLCleaner.new(filename: @file, class_config: @config).run

    # Check return value is the filename that was cleaned
    assert_equal @file, result
    assert_path_exists @file

    content = File.read(@file)

    assert_includes content, '<i>ItalicsOnly</i>'
    assert_includes content, 'KeepThis'
    refute_includes content, '<span'
    refute_includes content, '<hr'
    refute_includes content, 'RemoveMe'
  end
end
