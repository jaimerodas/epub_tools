require 'zip'
require 'fileutils'

class XHTMLExtractor
  def initialize(source_dir:, target_dir:)
    @source_dir = File.expand_path(source_dir)
    @target_dir = File.expand_path(target_dir)
    FileUtils.mkdir_p(@target_dir)
  end

  def extract_all
    epub_files.each do |epub_path|
      extract_xhtmls_from(epub_path)
    end
  end

  private

  def epub_files
    Dir.glob(File.join(@source_dir, '*.epub'))
  end

  def extract_xhtmls_from(epub_path)
    epub_name = File.basename(epub_path, '.epub')
    puts "Looking at #{epub_name}.epub"
    Zip::File.open(epub_path) do |zip_file|
      zip_file.each do |entry|
        next unless entry.name.downcase.end_with?('.xhtml')
        next if File.basename(entry.name).downcase == 'nav.xhtml'
        puts "Extracting #{entry}"
        output_path = File.join(@target_dir, "#{epub_name}_#{File.basename(entry.name)}")
        FileUtils.mkdir_p(File.dirname(output_path))
        entry.extract(output_path) { true } # overwrite if exists
      end
    end
  rescue Zip::Error => e
    warn "⚠️ Failed to process #{epub_path}: #{e.message}"
  end
end

# Allow running from the command line
if $PROGRAM_NAME == __FILE__
  if ARGV.size != 2
    puts "Usage: ruby #{__FILE__} <source_dir> <target_dir>"
    exit 1
  end

  service = XHTMLExtractor.new(source_dir: ARGV[0], target_dir: ARGV[1])
  service.extract_all
end
