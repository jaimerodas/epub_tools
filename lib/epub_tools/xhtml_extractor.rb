require 'zip'
require 'fileutils'

module EpubTools
  # Extracts .xhtml files from EPUB archives, excluding nav.xhtml
  class XHTMLExtractor
    def initialize(source_dir:, target_dir:, verbose: false)
      @source_dir = File.expand_path(source_dir)
      @target_dir = File.expand_path(target_dir)
      @verbose = verbose
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
      puts "Extracting from #{epub_name}.epub" if @verbose
      extracted_files = []
      Zip::File.open(epub_path) do |zip_file|
        zip_file.each do |entry|
          next unless entry.name.downcase.end_with?('.xhtml')
          next if File.basename(entry.name).downcase == 'nav.xhtml'
          output_path = File.join(@target_dir, "#{epub_name}_#{File.basename(entry.name)}")
          FileUtils.mkdir_p(File.dirname(output_path))
          entry.extract(output_path) { true }
          puts output_path if @verbose
          extracted_files << output_path
        end
      end
      extracted_files
    rescue Zip::Error => e
      warn "⚠️ Failed to process #{epub_path}: #{e.message}"
    end
  end
end