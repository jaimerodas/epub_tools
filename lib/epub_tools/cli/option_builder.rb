require 'optparse'

module EpubTools
  module CLI
    # Builds and manages command line options
    class OptionBuilder
      attr_reader :options, :required_keys, :parser

      # Initialize a new OptionBuilder
      # @param default_options [Hash] Default options to start with
      # @param required_keys [Array<Symbol>] Keys that must be present in the final options
      def initialize(default_options = {}, required_keys = [])
        @options = default_options.dup
        @required_keys = required_keys
        @parser = OptionParser.new
      end

      # Add banner to the option parser
      # @param text [String] Banner text
      # @return [self] for method chaining
      def with_banner(text)
        @parser.banner = text
        self
      end

      # Add help option to the parser
      # @return [self] for method chaining
      def with_help_option
        @parser.on('-h', '--help', 'Print this help') do
          puts @parser
          exit
        end
        self
      end

      # Add verbose option to the parser
      # @return [self] for method chaining
      def with_verbose_option
        @options[:verbose] = true unless @options.key?(:verbose)
        @parser.on('-q', '--quiet', 'Run quietly (default: verbose)') { |v| @options[:verbose] = !v }
        self
      end

      # Add input file option to the parser
      # @param description [String] Option description
      # @param required [Boolean] Whether this option is required
      # @return [self] for method chaining
      def with_input_file(description = 'Input file', required = true)
        desc = required ? "#{description} (required)" : description
        @parser.on('-i FILE', '--input-file FILE', desc) { |v| @options[:input_file] = v }
        self
      end

      # Add input directory option to the parser
      # @param description [String] Option description
      # @param required [Boolean] Whether this option is required
      # @return [self] for method chaining
      def with_input_dir(description = 'Input directory', required = true)
        desc = required ? "#{description} (required)" : description
        @parser.on('-i DIR', '--input-dir DIR', desc) { |v| @options[:input_dir] = v }
        self
      end

      # Add output directory option to the parser
      # @param description [String] Option description
      # @param default [String, nil] Default value
      # @return [self] for method chaining
      def with_output_dir(description = 'Output directory', default = nil)
        if default
          desc = "#{description} (default: #{default})"
          @options[:output_dir] = default unless @options.key?(:output_dir)
        else
          desc = "#{description} (required)"
        end
        @parser.on('-o DIR', '--output-dir DIR', desc) { |v| @options[:output_dir] = v }
        self
      end

      # Add output file option to the parser
      # @param description [String] Option description
      # @param required [Boolean] Whether this option is required
      # @return [self] for method chaining
      def with_output_file(description = 'Output file', required = true)
        desc = required ? "#{description} (required)" : description
        @parser.on('-o FILE', '--output-file FILE', desc) { |v| @options[:output_file] = v }
        self
      end

      # Add title option to the parser
      # @return [self] for method chaining
      def with_title_option
        @parser.on('-t TITLE', '--title TITLE', 'Book title (required)') { |v| @options[:title] = v }
        self
      end

      # Add author option to the parser
      # @return [self] for method chaining
      def with_author_option
        @parser.on('-a AUTHOR', '--author AUTHOR', 'Author name (required)') { |v| @options[:author] = v }
        self
      end

      # Add cover option to the parser
      # @return [self] for method chaining
      def with_cover_option
        @parser.on('-c PATH', '--cover PATH', 'Cover image file path (optional)') { |v| @options[:cover_image] = v }
        self
      end

      # Add a custom option to the parser
      # @param short [String] Short option flag
      # @param long [String] Long option flag
      # @param description [String] Option description
      # @param option_key [Symbol] Key in the options hash
      # @param block [Proc] Optional block for custom processing
      # @return [self] for method chaining
      def with_option(short, long, description, option_key)
        @parser.on(short, long, description) do |v|
          @options[option_key] = block_given? ? yield(v) : v
        end
        self
      end

      # Add a custom block to configure options
      # @yield [OptionParser, Hash] Yields the parser and options hash
      # @return [self] for method chaining
      def with_custom_options
        yield @parser, @options if block_given?
        self
      end

      # Parse the command line arguments
      # @param args [Array<String>] Command line arguments
      # @return [Hash] Parsed options
      # @raise [SystemExit] If required options are missing
      def parse(args = ARGV)
        begin
          @parser.parse!(args.dup)
          validate_required_keys
        rescue ArgumentError => e
          abort "#{e.message}\n#{@parser}"
        end
        @options
      end

      private

      # Validate that all required keys are present in the options
      # @raise [SystemExit] If required options are missing
      def validate_required_keys
        return if @required_keys.empty?

        missing = @required_keys.select { |k| @options[k].nil? }
        return if missing.empty?

        raise ArgumentError.new "Missing required options: #{missing_keys(missing)}"
      end

      def missing_keys(keys)
        keys.map { |k| "--#{k.to_s.tr('_', '-')}" }.join(', ')
      end
    end
  end
end
