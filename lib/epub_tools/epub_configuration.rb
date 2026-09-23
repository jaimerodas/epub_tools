# frozen_string_literal: true

require 'securerandom'
require 'time'

module EpubTools
  # Handles configuration parsing and setup for EPUB initialization
  class EpubConfiguration
    attr_reader :title, :author, :destination, :uuid, :modified,
                :cover_image_path, :verbose

    def initialize(options = {})
      @title = options.fetch(:title)
      @author = options.fetch(:author)
      @destination = File.expand_path(options.fetch(:destination))
      @uuid = "urn:uuid:#{SecureRandom.uuid}"
      @modified = Time.now.utc.iso8601
      @cover_image_path = options[:cover_image]
      @verbose = options[:verbose] || false
    end
  end
end
