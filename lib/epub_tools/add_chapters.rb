#!/usr/bin/env ruby
require 'nokogiri'
require 'fileutils'
require_relative 'loggable'

module EpubTools
  # Moves new chapters into an unpacked EPUB
  class AddChapters
    include Loggable
    # Initializes the class
    # @param options [Hash] Configuration options
    # @option options [String] :chapters_dir Directory from which to move the xhtml chapters.
    #                          It assumes the directory will contain one or more files named
    #                          +chapter_XX.xhtml+, where +XX+ is a number. (default: './chapters')
    # @option options [String] :epub_dir Unpacked EPUB directory to move the chapters to. It should
    #                          be the same directory that contains the +package.opf+ and +nav.xhtml+
    #                          files. (default: './epub/OEBPS')
    # @option options [Boolean] :verbose Whether to log progress to STDOUT (default: false)
    def initialize(options = {})
      @chapters_dir = File.expand_path(options[:chapters_dir] || './chapters')
      @epub_dir = File.expand_path(options[:epub_dir] || './epub/OEBPS')
      @opf_file = File.join(@epub_dir, 'package.opf')
      @nav_file = File.join(@epub_dir, 'nav.xhtml')
      @verbose = options[:verbose] || false

      validate_directories!
    end

    # It works like this:
    # - First, the *.xhtml files are moved from +chapters_dir+ over to +epub_dir+
    # - Then, new entries will be added to the manifest and spine of the EPUB's +package.opf+ file.
    #   It will sort the files by extracting the chapter number.
    # - Finally, it will update the +nav.xhtml+ file with the new chapters. Note that if there's a
    #   file named +chapter_0.xhtml+, it will be added to the +nav.xhtml+ as the Prologue.
    # @return [Array<String>] List of moved chapter filenames
    def run
      moved_files = move_chapters
      update_package_opf(moved_files)
      update_nav_xhtml(moved_files)
      moved_files.each { |f| log("Moved: #{f}") }
      moved_files
    end

    private

    def validate_directories!
      raise ArgumentError, "Chapters directory '#{@chapters_dir}' does not exist" unless Dir.exist?(@chapters_dir)

      raise ArgumentError, "EPUB directory '#{@epub_dir}' does not exist" unless Dir.exist?(@epub_dir)

      raise ArgumentError, "EPUB package.opf file missing at '#{@opf_file}'" unless File.exist?(@opf_file)

      return if File.exist?(@nav_file)

      raise ArgumentError, "EPUB nav.xhtml file missing at '#{@nav_file}'"
    end

    def move_chapters
      # Sort by chapter number (numeric)
      chapter_files = Dir.glob(File.join(@chapters_dir, '*.xhtml')).sort_by do |path|
        # extract first integer from filename (e.g. chapter_10.xhtml -> 10)
        File.basename(path)[/\d+/].to_i
      end

      raise ArgumentError, "No .xhtml files found in '#{@chapters_dir}'" if chapter_files.empty?

      chapter_files.each do |file|
        FileUtils.mv(file, @epub_dir)
      end
      chapter_files.map { |f| File.basename(f) }
    end

    def chapter_id(filename)
      match = filename.match(/chapter_(\d+)\.xhtml/)
      match ? "chap#{match[1]}" : File.basename(filename, '.xhtml')
    end

    def update_package_opf(filenames)
      doc = Nokogiri::XML(File.read(@opf_file)) { |config| config.default_xml.noblanks }
      manifest = doc.at_xpath('//xmlns:manifest')
      spine = doc.at_xpath('//xmlns:spine')

      filenames.each do |filename|
        id = chapter_id(filename)
        # Add <item> to the manifest if missing
        unless doc.at_xpath("//xmlns:item[@href='#{filename}']")
          item = Nokogiri::XML::Node.new('item', doc)
          item['id'] = id
          item['href'] = filename
          item['media-type'] = 'application/xhtml+xml'
          manifest.add_child(item)
        end

        # Add <itemref> to the spine if missing
        next if doc.at_xpath("//xmlns:itemref[@idref='#{id}']")

        itemref = Nokogiri::XML::Node.new('itemref', doc)
        itemref['idref'] = id
        spine.add_child(itemref)
      end

      File.write(@opf_file, doc.to_xml(indent: 2))
    end

    def update_nav_xhtml(filenames)
      doc = Nokogiri::XML(File.read(@nav_file)) { |config| config.default_xml.noblanks }
      nav = doc.at_xpath('//xmlns:nav[@epub:type="toc"]/xmlns:ol')

      filenames.each do |filename|
        # Create a new <li><a href="...">Label</a></li> element
        label = File.basename(filename, '.xhtml').gsub('_', ' ').capitalize
        label = 'Prologue' if label == 'Chapter 0'
        li = Nokogiri::XML::Node.new('li', doc)
        a  = Nokogiri::XML::Node.new('a', doc)
        a['href'] = filename
        a.content = label
        li.add_child(a)
        nav.add_child(li)
      end

      File.write(@nav_file, doc.to_xml(indent: 2))
    end
  end
end
