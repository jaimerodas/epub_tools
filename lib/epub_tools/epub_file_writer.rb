# frozen_string_literal: true

require 'fileutils'

module EpubTools
  # Handles writing files for EPUB structure
  class EpubFileWriter
    def initialize(destination)
      @destination = destination
    end

    # Creates the basic EPUB directory structure
    def create_structure
      FileUtils.mkdir_p("#{@destination}/META-INF")
      FileUtils.mkdir_p("#{@destination}/OEBPS")
    end

    # Writes the mimetype file
    def write_mimetype
      File.write("#{@destination}/mimetype", 'application/epub+zip')
    end

    # Writes the container.xml file
    def write_container
      content = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
          <rootfiles>
            <rootfile full-path="OEBPS/package.opf" media-type="application/oebps-package+xml"/>
          </rootfiles>
        </container>
      XML
      File.write("#{@destination}/META-INF/container.xml", content)
    end

    # Writes XHTML content to a file
    def write_xhtml(filename, content)
      File.write(File.join(@destination, 'OEBPS', filename), content)
    end

    # Writes the package.opf file
    def write_package_opf(content)
      File.write(File.join(@destination, 'OEBPS', 'package.opf'), content)
    end

    # Copies the project style.css to EPUB structure
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
end