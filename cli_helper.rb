require 'optparse'

# A simple helper to DRY CLI OptionParser usage across scripts
class CLIHelper
  # Parses ARGV into options hash, enforces required keys, and displays help/errors.
  # options: hash of defaults; required_keys: array of symbols required
  def self.parse(options = {}, required_keys = [], &block)
    parser = OptionParser.new do |opts|
      block.call(opts, options)
      opts.on('-h', '--help', 'Prints this help') { puts opts; exit }
    end
    begin
      parser.parse!
      puts options
      unless required_keys.empty?
        missing = required_keys.select { |k| options[k].nil? }
        unless missing.empty?
          STDERR.puts "Missing required options: #{missing.map { |k| "--#{k.to_s.gsub('_','-')}" }.join(', ')}"
          STDERR.puts parser
          exit 1
        end
      end
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
      STDERR.puts e.message
      STDERR.puts parser
      exit 1
    end
    options
  end
end
