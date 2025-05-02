require 'zip'
require 'fileutils'
require_relative 'loggable'

module EpubTools
  # Extracts text .xhtml files from EPUB archives, excluding nav.xhtml
  class XHTMLExtractor
    include Loggable
    # Initializes the class
    # @param options [Hash] Configuration options
    # @option options [String] :source_dir Directory containing source .epub files (required)
    # @option options [String] :target_dir Directory where .xhtml files will be extracted (required)
    # @option options [Boolean] :verbose Whether to print progress to STDOUT (default: false)
    def initialize(options = {})
      @source_dir = File.expand_path(options.fetch(:source_dir))
      @target_dir = File.expand_path(options.fetch(:target_dir))
      @verbose = options[:verbose] || false
      FileUtils.mkdir_p(@target_dir)
    end

    # Runs the extraction process
    # @return [Array<String>] Paths to all extracted XHTML files
    def run
      all_extracted_files = []
      epub_files.each do |epub_path|
        extracted = extract_xhtmls_from(epub_path)
        all_extracted_files.concat(extracted) if extracted
      end
      all_extracted_files
    end

    private

    def epub_files
      Dir.glob(File.join(@source_dir, '*.epub'))
    end

    def extract_xhtmls_from(epub_path)
      epub_name = File.basename(epub_path, '.epub')
      log "Extracting from #{epub_name}.epub"
      extracted_files = []
      Zip::File.open(epub_path) do |zip_file|
        zip_file.each do |entry|
          next unless entry.name.downcase.end_with?('.xhtml')
          next if File.basename(entry.name).downcase == 'nav.xhtml'

          output_path = File.join(@target_dir, "#{epub_name}_#{File.basename(entry.name)}")
          FileUtils.mkdir_p(File.dirname(output_path))
          entry.extract(output_path) { true }
          log output_path
          extracted_files << output_path
        end
      end
      extracted_files
    rescue Zip::Error => e
      warn "⚠️ Failed to process #{epub_path}: #{e.message}"
    end
  end
end
