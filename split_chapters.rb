require 'nokogiri'
require './text_style_class_finder'
require './xhtml_cleaner'
require 'yaml'

class SplitChapters
  # input_file: path to the source XHTML
  # book_title: title to use in HTML <title> tags
  # output_dir: where to write chapter files
  # output_prefix: filename prefix (e.g. "chapter")
  def initialize(input_file, book_title, output_dir = './chapters', output_prefix = 'chapter')
    @input_file    = input_file
    @book_title    = book_title
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
      if (m = node.text.match(/Chapter\s+(\d+)/i)) && %w[p span h3 h4].include?(node.name)
        # start a new chapter (skip the marker node so title isn't duplicated)
        chapters[current_number] = current_fragment.to_html if current_number
        current_number = m[1].to_i
        current_fragment = Nokogiri::HTML::DocumentFragment.parse('')
      elsif prologue_marker?(node)
        # start the prologue (skip the marker node)
        chapters[current_number] = current_fragment.to_html if current_number
        current_number = 0
        current_fragment = Nokogiri::HTML::DocumentFragment.parse('')
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

  def write_chapter_file(label, content)
    display_label = display_label(label)
    filename = File.join(@output_dir, "#{@output_prefix}_#{label}.xhtml")
    File.write(filename, <<~HTML)
      <?xml version="1.0" encoding="UTF-8"?>
      <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
        <head>
          <title>#{@book_title} - #{display_label}</title>
          <link rel="stylesheet" type="text/css" href="style.css"/>
        </head>
        <body>
          <h1>#{display_label}</h1>
          #{content}
        </body>
      </html>
    HTML
    puts "Wrote #{filename}"
    XHTMLCleaner.new(filename).call
  end

  def display_label(label)
    label > 0 ? "Chapter #{label}" : "Prologue"
  end

  # Detect a bolded Prologue marker
  def prologue_marker?(node)
    return false unless %w[h3 h4].include?(node.name)
    return false unless node.text.strip =~ /\APrologue\z/i
    true
  end

end

if __FILE__ == $0
  usage = "Usage: ruby #{__FILE__} input.xhtml \"Book Title\" [output_dir] [prefix]"
  input_file  = ARGV[0] || abort(usage)
  book_title  = ARGV[1] || abort(usage)
  output_dir  = ARGV[2] || './chapters'
  output_pref = ARGV[3] || 'chapter'
  SplitChapters.new(input_file, book_title, output_dir, output_pref).run
end
