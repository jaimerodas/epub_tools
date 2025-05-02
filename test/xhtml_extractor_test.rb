require_relative 'test_helper'
require 'zip'
require_relative '../lib/epub_tools/xhtml_extractor'

class XHTMLExtractorTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir
    @src = File.join(@tmp, 'src')
    @tgt = File.join(@tmp, 'tgt')
    Dir.mkdir(@src)
    @file = File.join(@src, 'sample.epub')
    Zip::File.open(@file, Zip::File::CREATE) do |zip|
      zip.get_output_stream('chapter1.xhtml') { |f| f.write '<html><body><p>One</p></body></html>' }
      zip.get_output_stream('nav.xhtml') { |f| f.write '<html><body>Nav</body></html>' }
      zip.get_output_stream('folder/ch2.xhtml') { |f| f.write '<html><body><p>Two</p></body></html>' }
    end
    @extractor = EpubTools::XHTMLExtractor.new(source_dir: @src, target_dir: @tgt)
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def test_extracts_xhtml_excluding_nav
    @extractor.run
    files = Dir.children(@tgt)
    assert_includes files, 'sample_chapter1.xhtml'
    assert_includes files, 'sample_ch2.xhtml'
    refute_includes files, 'nav.xhtml'
  end
end
