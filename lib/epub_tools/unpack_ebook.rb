require 'zip'
require 'fileutils'
require_relative 'loggable'

module EpubTools
  # Unpacks an EPUB (.epub file) into a directory
  class UnpackEbook
    include Loggable
    # Initializes the class
    # @param options [Hash] Configuration options
    # @option options [String] :epub_file Path to the .epub file to unpack (required)
    # @option options [String] :output_dir Directory to extract into (default: basename of epub_file without .epub)
    # @option options [Boolean] :verbose Whether to print progress to STDOUT (default: false)
    def initialize(options = {})
      @epub_file = File.expand_path(options.fetch(:epub_file))
      output_dir = options[:output_dir]
      @output_dir = output_dir.nil? || output_dir.empty? ? default_dir : output_dir
      @verbose = options[:verbose] || false
    end

    # Extracts all entries from the EPUB into the output directory. Returns the output
    # directory.
    def run
      validate!
      FileUtils.mkdir_p(@output_dir)
      Zip::File.open(@epub_file) do |zip|
        zip.each do |entry|
          dest_path = File.join(@output_dir, entry.name)
          if entry.directory?
            FileUtils.mkdir_p(dest_path)
          else
            FileUtils.mkdir_p(File.dirname(dest_path))
            entry.extract(dest_path) { true }
          end
        end
      end
      log "Unpacked #{File.basename(@epub_file)} to #{@output_dir}"
      @output_dir
    end

    private

    def default_dir
      [File.dirname(@epub_file), File.basename(@epub_file, '.epub')].join('/')
    end

    def validate!
      return if File.file?(@epub_file)

      raise ArgumentError, "EPUB file '#{@epub_file}' does not exist"
    end
  end
end
