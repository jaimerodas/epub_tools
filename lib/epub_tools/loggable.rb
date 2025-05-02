module EpubTools
  # Provides logging capability to classes that include it
  module Loggable
    # Logs a message if verbose mode is enabled
    # @param message [String] The message to log
    # @return [nil]
    def log(message)
      puts message if @verbose
    end
  end
end
