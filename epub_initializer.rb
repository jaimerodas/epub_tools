require 'fileutils'
require 'time'
require 'securerandom'

class EpubInitializer
  def initialize(title, author, destination)
    @title = title
    @author = author
    @destination = File.expand_path(destination)
    @uuid = "urn:uuid:#{SecureRandom.uuid}"
    @modified = Time.now.utc.iso8601
  end

  def run
    create_structure
    write_mimetype
    write_container
    write_package_opf
    write_nav
    write_style
  end

  private

  def create_structure
    FileUtils.mkdir_p("#{@destination}/META-INF")
    FileUtils.mkdir_p("#{@destination}/OEBPS")
  end

  def write_mimetype
    File.write("#{@destination}/mimetype", "application/epub+zip")
  end

  def write_container
    content = <<~XML
      <?xml version="1.0"?>
      <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
        <rootfiles>
          <rootfile full-path="OEBPS/package.opf" media-type="application/oebps-package+xml"/>
        </rootfiles>
      </container>
    XML
    File.write("#{@destination}/META-INF/container.xml", content)
  end

  def write_package_opf
    content = <<~XML
      <?xml version="1.0" encoding="utf-8"?>
      <package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id" xml:lang="en">
        <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
          <dc:identifier id="pub-id">#{@uuid}</dc:identifier>
          <dc:title>#{@title}</dc:title>
          <dc:creator>#{@author}</dc:creator>
          <meta property="dcterms:modified">#{@modified}</meta>
          <meta property="schema:accessMode">textual</meta>
          <meta property="schema:accessibilityFeature">unknown</meta>
          <meta property="schema:accessibilityHazard">none</meta>
          <meta property="schema:accessModeSufficient">textual</meta>
        </metadata>
        <manifest>
          <item id="style" href="style.css" media-type="text/css"/>
          <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
        </manifest>
        <spine>
          <itemref idref="chap0"/>
        </spine>
      </package>
    XML
    File.write("#{@destination}/OEBPS/package.opf", content)
  end

  def write_nav
    content = <<~XHTML
      <?xml version="1.0" encoding="utf-8"?>
      <html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="en">
        <head>
          <title>Table of Contents</title>
        </head>
        <body>
          <nav epub:type="toc" id="toc">
            <h1>Table of Contents</h1>
            <ol>
            </ol>
          </nav>
        </body>
      </html>
    XHTML
    File.write("#{@destination}/OEBPS/nav.xhtml", content)
  end

  def write_style
    src = File.join(Dir.pwd, 'style.css')
    dest = File.join(@destination, 'OEBPS', 'style.css')
    unless File.exist?(src)
      warn "Warning: style.css not found in project root (#{src}), skipping copy."
      return
    end
    FileUtils.cp(src, dest)
  end
end

# Allow running from the command line
if $PROGRAM_NAME == __FILE__
  if ARGV.size != 3
    puts "Usage: ruby #{__FILE__} <title> <author> <target_dir>"
    exit 1
  end

  service = EpubInitializer.new(ARGV[0], ARGV[1], ARGV[2])
  service.run
end
