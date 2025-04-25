require 'nokogiri'
require './text_style_class_finder'
require './xhtml_cleaner'

# === CONFIGURATION ===
INPUT_FILE = ARGV[0] || abort("Usage: ruby split_chapters.rb input.xhtml")
OUTPUT_PREFIX = 'chapter'
OUTPUT_DIR = './chapters' # make sure this exists or create it

# === SETUP ===
Dir.mkdir(OUTPUT_DIR) unless Dir.exist?(OUTPUT_DIR)

# Load and parse the XHTML file
html = File.read(INPUT_FILE)
doc = Nokogiri::HTML(html)

TextStyleClassFinder.new(INPUT_FILE).call

# Prepare variables
current_chapter_number = nil
chapter_docs = {}

# Traverse all elements inside <body>
body = doc.at('body')
builder = Nokogiri::HTML::DocumentFragment.parse("")
current_doc = nil

body.children.each do |node|
  if node.text =~ /Chapter\s+(\d+)/i && %w[p span h3].include?(node.name)
    # Save current chapter if one is open
    if current_chapter_number
      chapter_docs[current_chapter_number] = current_doc.to_html
    end

    # Start new chapter
    current_chapter_number = $1.to_i
    current_doc = Nokogiri::HTML::DocumentFragment.parse("")
    current_doc.add_child(node.dup)
  else
    current_doc&.add_child(node.dup)
  end
end

# Save the last chapter
if current_chapter_number
  chapter_docs[current_chapter_number] = current_doc.to_html
end

# Write to files
chapter_docs.each do |number, content|
  filename = File.join(OUTPUT_DIR, "#{OUTPUT_PREFIX}_#{number}.xhtml")
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
