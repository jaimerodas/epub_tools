# frozen_string_literal: true

require_relative 'command_registry'
require_relative 'option_builder'
require_relative 'command_options_configurator'

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
        @options_configurator = CommandOptionsConfigurator.new
      end

      # Run the CLI application
      # @param args [Array<String>] Command line arguments
      # @return [Boolean] true if the command was run successfully
      def run(args = ARGV)
        handle_version_flag(args)
        validate_command_args(args)

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

        builder = build_option_parser(cmd, command_config)
        execute_command(command_config, builder, args)
      end

      private

      # Handle version flag and exit if present
      # @param args [Array<String>] Command line arguments
      def handle_version_flag(args)
        return unless ['-v', '--version'].include?(args[0])

        puts EpubTools::VERSION
        exit 0
      end

      # Validate command arguments and exit if invalid
      # @param args [Array<String>] Command line arguments
      def validate_command_args(args)
        commands = registry.available_commands
        return unless args.empty? || !commands.include?(args[0])

        print_usage(commands)
        exit 1
      end

      # Build option parser for a command
      # @param cmd [String] Command name
      # @param command_config [Hash] Command configuration
      # @return [OptionBuilder] Configured option builder
      def build_option_parser(cmd, command_config)
        options = command_config[:default_options].dup
        required_keys = command_config[:required_keys]

        builder = OptionBuilder.new(options, required_keys)
                               .with_banner("Usage: #{program_name} #{cmd} [options]")
                               .with_help_option

        @options_configurator.configure(cmd, builder)
        builder
      end

      # Execute a command with parsed options
      # @param command_config [Hash] Command configuration
      # @param builder [OptionBuilder] Option builder instance
      # @param args [Array<String>] Command line arguments
      # @return [Object] Command instance
      def execute_command(command_config, builder, args)
        options = builder.parse(args)
        command_class = command_config[:class]
        command_instance = command_class.new(options)
        command_instance.run
        command_instance
      end

      # Print usage information
      # @param commands [Array<String>] Available commands
      def print_usage(_commands)
        puts "Usage: #{program_name} COMMAND [options]"
        puts 'Commands:'
        print_command_list
      end

      def print_command_list
        puts '  init      Initialize a bare-bones EPUB'
        puts '  extract   Extract XHTML files from EPUBs'
        puts '  split     Split XHTML into separate XHTMLs per chapter'
        puts '  add       Add chapter XHTML files into an EPUB'
        puts '  pack      Package an EPUB directory into a .epub file'
        puts '  unpack    Unpack an EPUB file into a directory'
        puts '  compile   Takes EPUBs in a dir and splits, cleans, and compiles into a single EPUB.'
        puts '  append    Extracts and splits EPUBs from a dir and appends them to an existing EPUB.'
      end
    end
  end
end
