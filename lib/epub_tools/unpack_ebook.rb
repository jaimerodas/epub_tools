require 'zip'
require 'fileutils'

module EpubTools
  # Unpacks an EPUB (.epub file) into a directory
  class UnpackEbook
    # epub_file: path to the .epub file
    # output_dir: directory to extract into; defaults to basename of epub_file without .epub
    def initialize(epub_file, output_dir = nil, verbose: false)
      @epub_file = File.expand_path(epub_file)
      default_dir = [File.dirname(@epub_file), File.basename(@epub_file, '.epub')].join("/")
      @output_dir = if output_dir.nil? || output_dir.empty?
                      default_dir
                    else
                      output_dir
                    end
      @verbose = verbose
    end

    # Extracts all entries from the EPUB into the output directory
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
      puts "Unpacked #{File.basename(@epub_file)} to #{@output_dir}" if @verbose
    end

    private

    def validate!
      unless File.file?(@epub_file)
        raise ArgumentError, "EPUB file '#{@epub_file}' does not exist"
      end
    end
  end
end
