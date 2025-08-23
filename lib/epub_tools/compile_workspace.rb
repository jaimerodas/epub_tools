# frozen_string_literal: true

require 'fileutils'

module EpubTools
  # Manages the build workspace for book compilation
  class CompileWorkspace
    attr_reader :build_dir

    def initialize(build_dir)
      @build_dir = build_dir
    end

    # Cleans the build directory
    def clean
      FileUtils.rm_rf(@build_dir)
    end

    # Prepares all necessary directories
    def prepare_directories
      FileUtils.mkdir_p(xhtml_dir)
      FileUtils.mkdir_p(chapters_dir)
    end

    # Gets the XHTML extraction directory
    def xhtml_dir
      @xhtml_dir ||= File.join(@build_dir, 'xhtml')
    end

    # Gets the chapters directory
    def chapters_dir
      @chapters_dir ||= File.join(@build_dir, 'chapters')
    end

    # Gets the EPUB build directory
    def epub_dir
      @epub_dir ||= File.join(@build_dir, 'epub')
    end
  end
end
