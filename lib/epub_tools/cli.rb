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

      # Register all commands
      runner.registry.register('add', EpubTools::AddChapters,
                               %i[chapters_dir epub_oebps_dir])

      runner.registry.register('extract', EpubTools::XHTMLExtractor,
                               %i[source_dir target_dir],
                               { verbose: true })

      runner.registry.register('split', EpubTools::SplitChapters,
                               %i[input_file book_title],
                               { output_dir: './chapters', prefix: 'chapter', verbose: true })

      runner.registry.register('init', EpubTools::EpubInitializer,
                               %i[title author destination],
                               { verbose: true })

      runner.registry.register('pack', EpubTools::PackEbook,
                               %i[input_dir output_file],
                               { verbose: true })

      runner.registry.register('unpack', EpubTools::UnpackEbook,
                               [:epub_file],
                               { verbose: true })

      runner.registry.register('compile', EpubTools::CompileBook,
                               %i[title author source_dir],
                               { verbose: true })

      runner
    end
  end
end
