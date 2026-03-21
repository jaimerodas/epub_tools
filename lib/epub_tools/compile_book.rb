# frozen_string_literal: true

require_relative 'book_builder'
require_relative 'epub_initializer'

module EpubTools
  # Compiles a new EPUB from source EPUBs by extracting, splitting, and repackaging
  class CompileBook < BookBuilder
    attr_reader :title, :author, :cover_image, :output_file

    def initialize(options = {})
      super
      @title       = options.fetch(:title)
      @author      = options.fetch(:author)
      @cover_image = options[:cover_image]
      @output_file = options[:output_file] || default_output_file
    end

    private

    def book_title = @title

    def output_path = @output_file

    def before_add_chapters
      log 'Initializing new EPUB...'
      options = { title: title, author: author, destination: @workspace.epub_dir }
      options[:cover_image] = cover_image if cover_image
      EpubInitializer.new(options).run
    end

    def default_output_file
      "#{title.gsub(' ', '_')}.epub"
    end
  end
end
