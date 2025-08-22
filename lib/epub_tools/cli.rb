# frozen_string_literal: true
require_relative 'cli/command_registry'
require_relative 'cli/option_builder'
require_relative 'cli/runner'

module EpubTools
  # CLI module - houses the object-oriented command line interface components
  module CLI
    # Create a new Runner instance configured with all available commands
    # @param program_name [String] Name of the program
    # @return [CLI::Runner] A configured runner instance
    def self.create_runner(program_name = nil)
      runner = Runner.new(program_name)
      register_all_commands(runner.registry)
      runner
    end

    # Register all available commands with their configurations
    # @param registry [CommandRegistry] The command registry to populate
    def self.register_all_commands(registry)
      registry.register('add', EpubTools::AddChapters, %i[chapters_dir oebps_dir])
      registry.register('extract', EpubTools::XHTMLExtractor, %i[source_dir target_dir], { verbose: true })
      registry.register('split', EpubTools::SplitChapters, %i[input_file book_title], { output_dir: './chapters', prefix: 'chapter', verbose: true })
      registry.register('init', EpubTools::EpubInitializer, %i[title author destination], { verbose: true })
      registry.register('pack', EpubTools::PackEbook, %i[input_dir output_file], { verbose: true })
      registry.register('unpack', EpubTools::UnpackEbook, [:epub_file], { verbose: true })
      registry.register('compile', EpubTools::CompileBook, %i[title author source_dir], { verbose: true })
    end
  end
end
