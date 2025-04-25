require 'nokogiri'
require './text_style_class_finder'
require './xhtml_cleaner'

class SplitChapters
  def initialize(input_file, output_dir = './chapters', output_prefix = 'chapter')
    @input_file    = input_file
    @output_dir    = output_dir
    @output_prefix = output_prefix
  end

  def run
    # Prepare output dir
    Dir.mkdir(@output_dir) unless Dir.exist?(@output_dir)

    # Read the doc
    doc = Nokogiri::HTML(File.read(@input_file))

    # Find Style Classes
    TextStyleClassFinder.new(@input_file).call

    chapters = extract_chapters(doc)
    write_chapter_files(chapters)
  end

  private

  def extract_chapters(doc)
    chapters = {}
    current_number = nil
    current_fragment = nil

    doc.at('body').children.each do |node|
      if node.text =~ /Chapter\s+(\d+)/i && %w[p span h3].include?(node.name)
        chapters[current_number] = current_fragment.to_html if current_number
        current_number = Regexp.last_match(1).to_i
        current_fragment = Nokogiri::HTML::DocumentFragment.parse('')
        current_fragment.add_child(node.dup)
      else
        current_fragment&.add_child(node.dup)
      end
    end

    chapters[current_number] = current_fragment.to_html if current_number
    chapters
  end

  def write_chapter_files(chapters)
    chapters.each do |number, content|
      write_chapter_file(number, content)
    end
  end

  def write_chapter_file(number, content)
    filename = File.join(@output_dir, "#{@output_prefix}_#{number}.xhtml")
    File.write(filename, <<~HTML)
      <?xml version="1.0" encoding="UTF-8"?>
      <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
        <head>
          <title>DM and the Dirty 20s - Chapter #{number}</title>
          <link rel="stylesheet" type="text/css" href="style.css"/>
        </head>
        <body>
          <h1>Chapter #{number}</h1>
          #{content}
        </body>
      </html>
    HTML
    puts "Wrote #{filename}"
    XHTMLCleaner.new(filename).call
  end

end

if __FILE__ == $0
  input_file    = ARGV[0] || abort("Usage: ruby #{__FILE__} input.xhtml [output_dir] [prefix]")
  output_dir    = ARGV[1] || './chapters'
  output_prefix = ARGV[2] || 'chapter'
  SplitChapters.new(input_file, output_dir, output_prefix).run
end
