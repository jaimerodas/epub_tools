# frozen_string_literal: true

require 'securerandom'
require 'time'

module EpubTools
  # Handles configuration parsing and setup for EPUB initialization
  class EpubConfiguration
    attr_reader :title, :author, :destination, :uuid, :modified,
                :cover_image_path, :cover_image_fname, :cover_image_media_type, :verbose

    def initialize(options = {})
      @title = options.fetch(:title)
      @author = options.fetch(:author)
      @destination = File.expand_path(options.fetch(:destination))
      @uuid = "urn:uuid:#{SecureRandom.uuid}"
      @modified = Time.now.utc.iso8601
      @cover_image_path = options[:cover_image]
      @cover_image_fname = nil
      @cover_image_media_type = nil
      @verbose = options[:verbose] || false
    end

    def cover_image?
      !@cover_image_path.nil?
    end

    def update_cover_info(fname, media_type)
      @cover_image_fname = fname
      @cover_image_media_type = media_type
    end
  end
end
