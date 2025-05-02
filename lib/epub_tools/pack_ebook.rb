require 'zip'
require 'fileutils'
require 'pathname'

module EpubTools
  # Packages an EPUB directory into a .epub file
  class PackEbook
    # [input_dir] Path to the EPUB directory (containing mimetype, META-INF, OEBPS)
    # [output_file] Path to resulting .epub file; if +nil+, defaults to <tt><input_dir>.epub</tt>
    def initialize(input_dir:, output_file: nil, verbose: false)
      @input_dir = File.expand_path(input_dir)
      default_name = "#{File.basename(@input_dir)}.epub"
      @output_file = if output_file.nil? || output_file.empty?
                       default_name
                     else
                       output_file
                     end
      @verbose = verbose
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
      puts "EPUB created: #{@output_file}" if @verbose
      @output_file
    end

    private

    def validate_input!
      unless Dir.exist?(@input_dir)
        raise ArgumentError, "Directory '#{@input_dir}' does not exist."
      end
      mimetype = File.join(@input_dir, 'mimetype')
      unless File.file?(mimetype)
        raise ArgumentError, "Error: 'mimetype' file missing in #{@input_dir}"
      end
    end

    def add_mimetype(zip)
      # Add mimetype first and uncompressed (Stored)
      zip.add_stored('mimetype', 'mimetype')
    end
  end
end
