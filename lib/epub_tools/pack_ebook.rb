require 'zip'
require 'fileutils'
require 'pathname'
require_relative 'loggable'

module EpubTools
  # Packages an EPUB directory into a .epub file
  class PackEbook
    include Loggable
    # Initializes the class
    # @param options [Hash] Configuration options
    # @option options [String] :input_dir Path to the EPUB directory (containing mimetype, META-INF, OEBPS) (required)
    # @option options [String] :output_file Path to resulting .epub file (default: <input_dir>.epub)
    # @option options [Boolean] :verbose Whether to print progress to STDOUT (default: false)
    def initialize(options = {})
      @input_dir = File.expand_path(options.fetch(:input_dir))
      default_name = "#{File.basename(@input_dir)}.epub"
      output_file = options[:output_file]
      @output_file = if output_file.nil? || output_file.empty?
                       default_name
                     else
                       output_file
                     end
      @verbose = options[:verbose] || false
    end

    # Runs the packaging process and returns the resulting file path
    def run
      validate_input!
      Dir.chdir(@input_dir) do
        # determine the output path: absolute stays as-is, otherwise sibling to input_dir
        target = Pathname.new(@output_file).absolute? ? @output_file : File.join('..', @output_file)
        FileUtils.rm_f(target)
        Zip::File.open(target, Zip::File::CREATE) do |zip|
          # Add mimetype first and uncompressed
          add_mimetype(zip)

          # Add all other files with compression, preserving paths
          Dir.glob('**/*', File::FNM_DOTMATCH).sort.each do |entry|
            next if ['.', '..', 'mimetype'].include?(entry)
            next if File.directory?(entry)

            zip.add(entry, entry)
          end
        end
      end
      log "EPUB created: #{@output_file}"
      @output_file
    end

    private

    def validate_input!
      raise ArgumentError, "Directory '#{@input_dir}' does not exist." unless Dir.exist?(@input_dir)

      mimetype = File.join(@input_dir, 'mimetype')
      return if File.file?(mimetype)

      raise ArgumentError, "Error: 'mimetype' file missing in #{@input_dir}"
    end

    def add_mimetype(zip)
      # Add mimetype first and uncompressed (Stored)
      zip.add_stored('mimetype', 'mimetype')
    end
  end
end
