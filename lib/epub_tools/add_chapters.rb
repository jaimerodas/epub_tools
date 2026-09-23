#!/usr/bin/env ruby
# frozen_string_literal: true

require 'nokogiri'
require 'fileutils'
require_relative 'loggable'
require_relative 'chapter_order'

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
      @epub_dir = File.expand_path(options[:oebps_dir] || './epub/OEBPS')
      @opf_file = File.join(@epub_dir, 'package.opf')
      @nav_file = File.join(@epub_dir, 'nav.xhtml')
      @verbose = options[:verbose] || false

      validate_directories!
    end

    # It works like this:
    # - First, the *.xhtml files are moved from +chapters_dir+ over to +epub_dir+
    # - Then, new entries will be added to the manifest and spine of the EPUB's +package.opf+ file.
    #   Chapters are placed in reading order by their number (+chapter_12a+ goes between 12 and 13),
    #   even when the book already contains later chapters.
    # - Finally, it will update the +nav.xhtml+ file with the new chapters, labelled with each chapter's
    #   <tt><h1></tt>. Without one, the label comes from the filename (+chapter_0.xhtml+ is the Prologue).
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
      chapter_files = Dir.glob(File.join(@chapters_dir, '*.xhtml')).sort_by do |path|
        ChapterOrder.sort_key(path)
      end

      raise ArgumentError, "No .xhtml files found in '#{@chapters_dir}'" if chapter_files.empty?

      chapter_files.each do |file|
        FileUtils.mv(file, @epub_dir)
      end
      chapter_files.map { |f| File.basename(f) }
    end

    def chapter_id(filename)
      match = filename.match(/chapter_(\d+(?:_5)?)\.xhtml/)
      match ? "chap#{match[1]}" : File.basename(filename, '.xhtml')
    end

    def update_package_opf(filenames)
      doc = Nokogiri::XML(File.read(@opf_file)) { |config| config.default_xml.noblanks }
      manifest = doc.at_xpath('//xmlns:manifest')
      spine = doc.at_xpath('//xmlns:spine')

      filenames.each { |filename| update_opf_for_file(doc, manifest, spine, filename) }

      File.write(@opf_file, doc.to_xml(indent: 2))
    end

    def update_nav_xhtml(filenames)
      doc = Nokogiri::XML(File.read(@nav_file)) { |config| config.default_xml.noblanks }
      nav = doc.at_xpath('//xmlns:nav[@epub:type="toc"]/xmlns:ol')

      filenames.each do |filename|
        ChapterOrder.insert(nav, create_nav_link(doc, filename), filename) { |li| li.at_xpath('xmlns:a')&.[]('href') }
      end

      File.write(@nav_file, doc.to_xml(indent: 2))
    end

    def create_nav_link(doc, filename)
      li = Nokogiri::XML::Node.new('li', doc)
      a = Nokogiri::XML::Node.new('a', doc)
      a['href'] = filename
      a.content = format_chapter_label(filename)
      li.add_child(a)
      li
    end

    # Uses the chapter's own <h1> when it has one, falling back to a label derived from the filename
    def format_chapter_label(filename)
      heading = Nokogiri::XML(File.read(File.join(@epub_dir, filename))).at_xpath('//*[local-name()="h1"]')
      return heading.text.strip unless heading.nil? || heading.text.strip.empty?

      basename = File.basename(filename, '.xhtml')
      return 'Prologue' if basename == 'chapter_0'

      if (m = basename.match(/chapter_(\d+)_5/))
        "Chapter #{m[1]}.5"
      else
        basename.gsub('_', ' ').capitalize
      end
    end

    def update_opf_for_file(doc, manifest, spine, filename)
      id = chapter_id(filename)
      add_manifest_item(doc, manifest, filename, id) unless manifest_item_exists?(doc, filename)
      add_spine_itemref(doc, spine, id, filename) unless spine_itemref_exists?(doc, id)
    end

    def manifest_item_exists?(doc, filename)
      doc.at_xpath("//xmlns:item[@href='#{filename}']")
    end

    def spine_itemref_exists?(doc, id)
      doc.at_xpath("//xmlns:itemref[@idref='#{id}']")
    end

    def add_manifest_item(doc, manifest, filename, id)
      item = Nokogiri::XML::Node.new('item', doc)
      item['id'] = id
      item['href'] = filename
      item['media-type'] = 'application/xhtml+xml'
      manifest.add_child(item)
    end

    def add_spine_itemref(doc, spine, id, filename)
      itemref = Nokogiri::XML::Node.new('itemref', doc)
      itemref['idref'] = id
      hrefs = doc.xpath('//xmlns:manifest/xmlns:item').to_h { |item| [item['id'], item['href']] }
      ChapterOrder.insert(spine, itemref, filename) { |ref| hrefs[ref['idref']] }
    end
  end
end
