require 'nokogiri'
require 'yaml'

class TextStyleClassFinder
  def initialize(file_path, output_path = 'text_style_classes.yaml', verbose = false)
    @file_path = file_path
    @output_path = output_path
    @verbose = verbose
    raise ArgumentError, "File does not exist: #{@file_path}" unless File.exist?(@file_path)
  end

  def call
    doc = Nokogiri::HTML(File.read(@file_path))
    style_blocks = doc.xpath('//style').map(&:text).join("\n")

    italics = extract_classes(style_blocks, /font-style\s*:\s*italic/)
    bolds   = extract_classes(style_blocks, /font-weight\s*:\s*700/)

    print_summary(italics, bolds) if @verbose

    data = {
      "italics" => italics,
      "bolds"   => bolds
    }
    File.write(@output_path, data.to_yaml)
  end

  private

  def extract_classes(style_text, pattern)
    regex = /\.([\w-]+)\s*{[^}]*#{pattern.source}[^}]*}/i
    style_text.scan(regex).flatten.uniq
  end

  def print_summary(italics, bolds)
    unless italics.empty?
      puts "Classes with font-style: italic: #{italics.join(", ")}"
    end

    unless bolds.empty?
      puts "Classes with font-weight: 700: #{bolds.join(", ")}"
    end
  end
end

# If executed directly from command line
if __FILE__ == $0
  file_path = ARGV[0]
  unless file_path
    puts "Usage: ruby text_style_class_finder.rb yourfile.xhtml"
    exit 1
  end

  TextStyleClassFinder.new(file_path).call
end
