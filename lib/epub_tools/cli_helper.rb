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
  end
end
