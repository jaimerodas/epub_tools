module EpubTools
  module CLI
    # Manages the registration and retrieval of commands
    class CommandRegistry
      attr_reader :commands

      def initialize
        @commands = {}
      end

      # Register a new command in the registry
      # @param name [String] the command name
      # @param command_class [Class] the class that implements the command
      # @param required_keys [Array<Symbol>] keys that must be present in options
      # @param default_options [Hash] default options for the command
      # @return [self]
      def register(name, command_class, required_keys = [], default_options = {})
        @commands[name] = {
          class: command_class,
          required_keys: required_keys,
          default_options: default_options
        }
        self
      end

      # Get a command by name
      # @param name [String] the command name
      # @return [Hash, nil] the command configuration or nil if not found
      def get(name)
        @commands[name]
      end

      # Get all available command names
      # @return [Array<String>] list of registered command names
      def available_commands
        @commands.keys
      end

      # Check if a command is registered
      # @param name [String] the command name
      # @return [Boolean] true if command exists
      def command_exists?(name)
        @commands.key?(name)
      end
    end
  end
end
