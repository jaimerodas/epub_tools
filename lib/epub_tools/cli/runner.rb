require_relative 'command_registry'
require_relative 'option_builder'

module EpubTools
  module CLI
    # Main runner for the CLI application
    class Runner
      attr_reader :registry, :program_name

      # Initialize a new CLI Runner
      # @param program_name [String] Name of the program
      def initialize(program_name = nil)
        @registry = CommandRegistry.new
        @program_name = program_name || File.basename($PROGRAM_NAME)
      end

      # Run the CLI application
      # @param args [Array<String>] Command line arguments
      # @return [Boolean] true if the command was run successfully
      def run(args = ARGV)
        # Handle global version flag
        if ['-v', '--version'].include?(args[0])
          puts EpubTools::VERSION
          exit 0
        end

        commands = registry.available_commands

        if args.empty? || !commands.include?(args[0])
          print_usage(commands)
          exit 1
        end

        cmd = args.shift
        handle_command(cmd, args)
      end

      # Handle a specific command
      # @param cmd [String] Command name
      # @param args [Array<String>] Command line arguments
      # @return [Boolean] true if the command was run successfully
      def handle_command(cmd, args = ARGV)
        command_config = registry.get(cmd)
        return false unless command_config

        options = command_config[:default_options].dup
        required_keys = command_config[:required_keys]

        builder = OptionBuilder.new(options, required_keys)
                               .with_banner("Usage: #{program_name} #{cmd} [options]")
                               .with_help_option

        # Configure command-specific options
        configure_command_options(cmd, builder)

        # Parse arguments and run the command
        options = builder.parse(args)
        command_class = command_config[:class]
        command_class.new(options).run
        true
      end

      private

      # Print usage information
      # @param commands [Array<String>] Available commands
      def print_usage(_commands)
        puts <<~USAGE
          Usage: #{program_name} COMMAND [options]
          Commands:
            init      Initialize a bare-bones EPUB
            extract   Extract XHTML files from EPUBs
            split     Split XHTML into separate XHTMLs per chapter
            add       Add chapter XHTML files into an EPUB
            pack      Package an EPUB directory into a .epub file
            unpack    Unpack an EPUB file into a directory
            compile   Takes EPUBs in a dir and splits, cleans, and compiles into a single EPUB.
        USAGE
      end

      # Configure command-specific options
      # @param cmd [String] Command name
      # @param builder [OptionBuilder] Option builder instance
      def configure_command_options(cmd, builder)
        case cmd
        when 'add'
          builder.with_custom_options do |opts, options|
            opts.on('-c DIR', '--chapters-dir DIR', 'Chapters directory (required)') { |v| options[:chapters_dir] = v }
            opts.on('-e DIR', '--epub-oebps-dir DIR', 'EPUB OEBPS directory (required)') do |v|
              options[:epub_oebps_dir] = v
            end
          end

        when 'extract'
          builder.with_custom_options do |opts, options|
            opts.on('-s DIR', '--source-dir DIR', 'Directory with EPUBs to extract XHTMLs from (required)') do |v|
              options[:source_dir] = v
            end
            opts.on('-t DIR', '--target-dir DIR',
                    'Directory where the XHTML files will be extracted to (required)') do |v|
              options[:target_dir] = v
            end
          end
          .with_verbose_option

        when 'split'
          builder.with_custom_options do |opts, options|
            opts.on('-i FILE', '--input FILE', 'Source XHTML file (required)') { |v| options[:input_file] = v }
            opts.on('-t TITLE', '--title TITLE', 'Book title for HTML <title> tags (required)') do |v|
              options[:book_title] = v
            end
            opts.on('-o DIR', '--output-dir DIR',
                    "Output directory for chapter files (default: #{options[:output_dir]})") do |v|
              options[:output_dir] = v
            end
            opts.on('-p PREFIX', '--prefix PREFIX',
                    "Filename prefix for chapters (default: #{options[:prefix]})") do |v|
              options[:prefix] = v
            end
          end
          .with_verbose_option

        when 'init'
          builder.with_title_option
                 .with_author_option
                 .with_custom_options do |opts, options|
            opts.on('-o DIR', '--output-dir DIR', 'Destination EPUB directory (required)') do |v|
              options[:destination] = v
            end
          end
            .with_cover_option

        when 'pack'
          builder.with_input_dir('EPUB directory to package')
                 .with_output_file('Output EPUB file path')
                 .with_verbose_option

        when 'unpack'
          builder.with_custom_options do |opts, options|
            opts.on('-i FILE', '--input-file FILE', 'EPUB file to unpack (required)') { |v| options[:epub_file] = v }
            opts.on('-o DIR', '--output-dir DIR', 'Output directory to extract into (default: basename of epub)') do |v|
              options[:output_dir] = v
            end
          end
          .with_verbose_option

        when 'compile'
          builder.with_title_option
                 .with_author_option
                 .with_custom_options do |opts, options|
            opts.on('-s DIR', '--source-dir DIR', 'Directory with EPUBs to extract XHTMLs from (required)') do |v|
              options[:source_dir] = v
            end
            opts.on('-o FILE', '--output FILE', 'EPUB to create (default: book title in source dir)') do |v|
              options[:output_file] = v
            end
          end
            .with_cover_option
            .with_verbose_option
        end
      end
    end
  end
end
