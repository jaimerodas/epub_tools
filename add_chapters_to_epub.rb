require 'nokogiri'
require 'fileutils'

class AddChaptersToEpub
  def initialize(chapters_dir = './chapters', epub_dir = './epub/OEBPS')
    @chapters_dir = chapters_dir
    @epub_dir = epub_dir
    @opf_file = File.join(@epub_dir, 'package.opf')
    @nav_file = File.join(@epub_dir, 'nav.xhtml')
  end

  def run
    puts "Moving chapter files..."
    moved_files = move_chapters

    puts "Updating package.opf..."
    update_package_opf(moved_files)

    puts "Updating nav.xhtml..."
    update_nav_xhtml(moved_files)

    puts "All done! #{moved_files.size} chapters added."
  end

  private

  def move_chapters
    chapter_files = Dir.glob(File.join(@chapters_dir, '*.xhtml')).sort
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
    doc = Nokogiri::XML(File.read(@opf_file))
    manifest = doc.at_xpath('//xmlns:manifest')
    spine = doc.at_xpath('//xmlns:spine')

    filenames.each do |filename|
      id = chapter_id(filename)
      unless doc.at_xpath("//xmlns:item[@href='#{filename}']")
        manifest.add_child(%(<item id="#{id}" href="#{filename}" media-type="application/xhtml+xml"/>\n))
      end

      unless doc.at_xpath("//xmlns:itemref[@idref='#{id}']")
        spine.add_child(%(<itemref idref="#{id}"/>\n))
      end
    end

    File.write(@opf_file, doc.to_xml(indent: 2))
  end

  def update_nav_xhtml(filenames)
    doc = Nokogiri::XML(File.read(@nav_file))
    nav = doc.at_xpath('//xmlns:nav[@epub:type="toc"]/xmlns:ol')

    filenames.each do |filename|
      label = File.basename(filename, '.xhtml').gsub('_', ' ').capitalize
      nav.add_child(%(<li><a href="#{filename}">#{label}</a></li>\n))
    end

    File.write(@nav_file, doc.to_xml(indent: 2))
  end
end

if __FILE__ == $0
  chapters_dir = ARGV[0] || './chapters'
  epub_dir = ARGV[1] || './epub/OEBPS'
  AddChaptersToEpub.new(chapters_dir, epub_dir).run
end
