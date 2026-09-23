# frozen_string_literal: true

require 'optparse'
require_relative 'version'
require_relative 'epub_initializer'
require_relative 'xhtml_extractor'
require_relative 'split_chapters'
require_relative 'pdf_converter'
require_relative 'add_chapters'
require_relative 'pack_ebook'
require_relative 'unpack_ebook'
require_relative 'set_cover'
require_relative 'compile_book'
require_relative 'append_book'

module EpubTools
  # Command line interface: parses a command's flags and runs the class that implements it
  module CLI
    TITLE = ['-t TITLE', '--title TITLE', 'Book title', :title, :required].freeze
    AUTHOR = ['-a AUTHOR', '--author AUTHOR', 'Author name', :author, :required].freeze
    COVER = ['-c PATH', '--cover PATH', 'Cover image file path (optional)', :cover_image].freeze
    BOOK_TITLE = ['-t TITLE', '--title TITLE', 'Book title for HTML <title> tags', :book_title, :required].freeze
    CHAPTERS_OUT = ['-o DIR', '--output-dir DIR', 'Output directory for chapter files (default: ./chapters)',
                    :output_dir].freeze

    # Each command's class, usage summary and flags as [short, long, description, option key, :required].
    # Commands log progress unless run with -q, except those marked <tt>verbose: false</tt>.
    COMMANDS = {
      'init' => { class: EpubInitializer, summary: 'Initialize a bare-bones EPUB',
                  flags: [TITLE, AUTHOR, ['-o DIR', '--output-dir DIR', 'Destination EPUB directory',
                                          :destination, :required], COVER] },
      'extract' => { class: XHTMLExtractor, summary: 'Extract XHTML files from EPUBs',
                     flags: [['-s DIR', '--source-dir DIR', 'Directory with EPUBs to extract XHTMLs from',
                              :source_dir, :required],
                             ['-t DIR', '--target-dir DIR',
                              'Directory where the XHTML files will be extracted to', :target_dir, :required]] },
      'split' => { class: SplitChapters, summary: 'Split XHTML into separate XHTMLs per chapter',
                   flags: [['-i FILE', '--input FILE', 'Source XHTML file', :input_file, :required], BOOK_TITLE,
                           CHAPTERS_OUT] },
      'pdf' => { class: PDFConverter, summary: 'Convert chapter PDFs into chapter XHTMLs',
                 flags: [['-s DIR', '--source-dir DIR', "Dir of PDFs named '12a Title.pdf'", :source_dir, :required],
                         BOOK_TITLE, CHAPTERS_OUT] },
      'add' => { class: AddChapters, summary: 'Add chapter XHTML files into an EPUB', verbose: false,
                 flags: [['-c DIR', '--chapters-dir DIR', 'Chapters directory', :chapters_dir, :required],
                         ['-e DIR', '--oebps-dir DIR', 'EPUB OEBPS directory', :oebps_dir, :required]] },
      'pack' => { class: PackEbook, summary: 'Package an EPUB directory into a .epub file',
                  flags: [['-i DIR', '--input-dir DIR', 'EPUB directory to package', :input_dir, :required],
                          ['-o FILE', '--output-file FILE', 'Output EPUB file path', :output_file, :required]] },
      'unpack' => { class: UnpackEbook, summary: 'Unpack an EPUB file into a directory',
                    flags: [['-i FILE', '--input-file FILE', 'EPUB file to unpack', :epub_file, :required],
                            ['-o DIR', '--output-dir DIR',
                             'Output directory to extract into (default: basename of epub)', :output_dir]] },
      'cover' => { class: SetCover, summary: 'Add or replace the cover of an EPUB',
                   flags: [['-i FILE', '--input-file FILE', 'EPUB to add the cover to', :epub_file, :required],
                           ['-c PATH', '--cover PATH', 'Cover image: jpg, png, gif or svg', :cover_image, :required]] },
      'compile' => { class: CompileBook,
                     summary: 'Takes EPUBs and/or chapter PDFs in a dir and compiles them into a single EPUB.',
                     flags: [TITLE, AUTHOR,
                             ['-s DIR', '--source-dir DIR', 'Directory with EPUBs and/or chapter PDFs',
                              :source_dir, :required],
                             ['-o FILE', '--output FILE', 'EPUB to create (default: <Book_Title>.epub)',
                              :output_file], COVER] },
      'append' => { class: AppendBook,
                    summary: 'Takes EPUBs and/or chapter PDFs in a dir and appends them to an existing EPUB.',
                    flags: [['-s DIR', '--source-dir DIR',
                             'Directory with EPUBs and/or chapter PDFs to append', :source_dir, :required],
                            ['-t FILE', '--target-epub FILE', 'Existing EPUB file to append to',
                             :target_epub, :required]] }
    }.freeze

    module_function

    # Runs the command named by the first argument, or prints the version or usage
    # @param args [Array<String>] Command line arguments
    # @return [Object] The command instance that ran
    def run(args)
      if ['-v', '--version'].include?(args[0])
        puts VERSION
        exit
      end
      usage unless COMMANDS.key?(args[0])

      name, *rest = args
      COMMANDS[name][:class].new(parse(name, rest)).tap(&:run)
    end

    # @param name [String] Command name
    # @param args [Array<String>] The command's arguments
    # @return [Hash] Options for the command's class; exits with the help text if they are invalid
    def parse(name, args)
      command = COMMANDS.fetch(name)
      options = verbose?(command) ? { verbose: true } : {}
      parser = parser_for(name, command, options)
      parser.parse(args)
      missing = missing_flags(command, options)
      abort "Missing required options: #{missing.join(', ')}\n#{parser}" if missing.any?

      options
    rescue OptionParser::ParseError => e
      abort "#{e.message}\n#{parser}"
    end

    # @return [Array<String>] The long names of required flags that were not given, e.g. +--title+
    def missing_flags(command, options)
      command[:flags].filter_map { |_, long, _, key, required| long.split.first if required && options[key].nil? }
    end

    def parser_for(name, command, options)
      OptionParser.new("Usage: #{program_name} #{name} [options]") do |parser|
        command[:flags].each do |short, long, desc, key, required|
          parser.on(short, long, required ? "#{desc} (required)" : desc) { |v| options[key] = v }
        end
        parser.on('-q', '--quiet', 'Run quietly (default: verbose)') { options[:verbose] = false } if verbose?(command)
        parser.on('-h', '--help', 'Print this help') do
          puts parser
          exit
        end
      end
    end

    def usage
      puts "Usage: #{program_name} COMMAND [options]", 'Commands:'
      COMMANDS.each { |name, command| puts "  #{name.ljust(9)} #{command[:summary]}" }
      exit 1
    end

    def verbose?(command) = command.fetch(:verbose, true)

    def program_name = File.basename($PROGRAM_NAME)
  end
end
