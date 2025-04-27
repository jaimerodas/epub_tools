require_relative 'test_helper'
require 'yaml'
require_relative '../text_style_class_finder'

class TextStyleClassFinderTest < Minitest::Test
  def setup
    @tmp = Dir.mktmpdir
    @xhtml = File.join(@tmp, 'doc.xhtml')
    content = <<~HTML
      <html><head><style>
        .c1 { font-style: italic; }
        .c2 { font-weight: 700; }
        .other { color: red; }
      </style></head><body></body></html>
    HTML
    File.write(@xhtml, content)
    @yaml = File.join(@tmp, 'classes.yaml')
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def test_finds_italic_and_bold_classes
    TextStyleClassFinder.new(@xhtml, @yaml).call
    data = YAML.load_file(@yaml)
    assert_equal ['c1'], data['italics']
    assert_equal ['c2'], data['bolds']
  end

  def test_verbose_mode
    text = <<~OUTPUT
    Classes with font-style: italic: c1
    Classes with font-weight: 700: c2
    OUTPUT
    assert_output(text) do
      TextStyleClassFinder.new(@xhtml, @yaml, true).call
    end
  end
end
