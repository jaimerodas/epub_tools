#!/usr/bin/env ruby
require 'nokogiri'
require 'fileutils'

module EpubTools
  class AddChaptersToEpub
    def initialize(chapters_dir = './chapters', epub_dir = './epub/OEBPS', verbose = false)
      @chapters_dir = chapters_dir
      @epub_dir = epub_dir
      @opf_file = File.join(@epub_dir, 'package.opf')
      @nav_file = File.join(@epub_dir, 'nav.xhtml')
      @verbose = verbose
    end

    def run
      moved_files = move_chapters
      update_package_opf(moved_files)
      update_nav_xhtml(moved_files)
      @verbose ? moved_files.each {|f| puts "Moved: #{f}"} : moved_files
    end

    private

    def move_chapters
      # Sort by chapter number (numeric)
      chapter_files = Dir.glob(File.join(@chapters_dir, '*.xhtml')).sort_by do |path|
        # extract first integer from filename (e.g. chapter_10.xhtml -> 10)
        File.basename(path)[/\d+/].to_i
      end
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
        unless doc.at_xpath("//xmlns:itemref[@idref='#{id}']")
          itemref = Nokogiri::XML::Node.new('itemref', doc)
          itemref['idref'] = id
          spine.add_child(itemref)
        end
      end

      File.write(@opf_file, doc.to_xml(indent: 2))
    end

    def update_nav_xhtml(filenames)
      doc = Nokogiri::XML(File.read(@nav_file)) { |config| config.default_xml.noblanks }
      nav = doc.at_xpath('//xmlns:nav[@epub:type="toc"]/xmlns:ol')

      filenames.each do |filename|
        # Create a new <li><a href="...">Label</a></li> element
        label = File.basename(filename, '.xhtml').gsub('_', ' ').capitalize
        label = "Prologue" if label == "Chapter 0"
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
