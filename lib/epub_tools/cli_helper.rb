require 'optparse'

module EpubTools
  # A simple helper to DRY CLI OptionParser usage across commands
  class CLIHelper
    # Parses ARGV into options hash, enforces required keys, and displays help/errors.
    # options: hash of defaults; required_keys: array of symbols required
    def self.parse(options = {}, required_keys = [], &block)
      parser = OptionParser.new do |opts|
        block.call(opts, options)
        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end
      end
      begin
        parser.parse!
        unless required_keys.empty?
          missing = required_keys.select { |k| options[k].nil? }
          unless missing.empty?
            warn "Missing required options: #{missing.map { |k| "--#{k.to_s.gsub('_', '-')}" }.join(', ')}"
            warn parser
            exit 1
          end
        end
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
        warn e.message
        warn parser
        exit 1
      end
      options
    end

    # Add common option definitions as helper methods
    def self.add_verbose_option(opts, options)
      options[:verbose] = true unless options.key?(:verbose)
      opts.on('-q', '--quiet', 'Run quietly (default: verbose)') { |v| options[:verbose] = !v }
    end

    def self.add_input_file_option(opts, options, description = 'Input file', required = true)
      desc = required ? "#{description} (required)" : description
      opts.on('-i FILE', '--input-file FILE', desc) { |v| options[:input_file] = v }
    end

    def self.add_input_dir_option(opts, options, description = 'Input directory', required = true)
      desc = required ? "#{description} (required)" : description
      opts.on('-i DIR', '--input-dir DIR', desc) { |v| options[:input_dir] = v }
    end

    def self.add_output_dir_option(opts, options, description = 'Output directory', default = nil)
      if default
        desc = "#{description} (default: #{default})"
        options[:output_dir] = default unless options.key?(:output_dir)
      else
        desc = "#{description} (required)"
      end
      opts.on('-o DIR', '--output-dir DIR', desc) { |v| options[:output_dir] = v }
    end

    def self.add_output_file_option(opts, options, description = 'Output file', required = true)
      desc = required ? "#{description} (required)" : description
      opts.on('-o FILE', '--output-file FILE', desc) { |v| options[:output_file] = v }
    end

    def self.add_title_option(opts, options)
      opts.on('-t TITLE', '--title TITLE', 'Book title (required)') { |v| options[:title] = v }
    end

    def self.add_author_option(opts, options)
      opts.on('-a AUTHOR', '--author AUTHOR', 'Author name (required)') { |v| options[:author] = v }
    end

    def self.add_cover_option(opts, options)
      opts.on('-c PATH', '--cover PATH', 'Cover image file path (optional)') { |v| options[:cover_image] = v }
    end

    # Command registry for simpler command definition
    @@commands = {}

    def self.register_command(name, command_class, required_keys = [], default_options = {})
      @@commands[name] = {
        class: command_class,
        required_keys: required_keys,
        default_options: default_options
      }
    end

    def self.handle_command(prog, cmd, options_config = {}, &block)
      command = @@commands[cmd]
      return false unless command

      options = command[:default_options].dup

      parse(options, command[:required_keys]) do |opts, o|
        opts.banner = "Usage: #{prog} #{cmd} [options]"
        block.call(opts, o) if block_given?
      end

      command[:class].new(options).run
      true
    end

    def self.commands
      @@commands.keys
    end
  end
end
