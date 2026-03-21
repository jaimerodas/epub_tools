# frozen_string_literal: true

require 'nokogiri'
require_relative 'book_builder'
require_relative 'unpack_ebook'

module EpubTools
  # Appends chapters from source EPUBs to an existing target EPUB
  class AppendBook < BookBuilder
    attr_reader :target_epub

    def initialize(options = {})
      super
      @target_epub = File.expand_path(options.fetch(:target_epub))
    end

    private

    def book_title
      @book_title ||= read_target_title
    end

    def output_path = @target_epub

    def prepare_epub
      backup_target
      unpack_target
    end

    def before_add_chapters
      detect_conflicts
    end

    def finalize_and_cleanup
      log "Done. Updated EPUB: #{@target_epub} (backup: #{@backup_path})"
      @workspace.clean
      @target_epub
    end

    def backup_target
      @backup_path = "#{@target_epub}.bak"
      log "Backing up target to '#{@backup_path}'..."
      FileUtils.cp(@target_epub, @backup_path)
    end

    def unpack_target
      log 'Unpacking target EPUB...'
      UnpackEbook.new(epub_file: @target_epub, output_dir: @workspace.epub_dir, verbose: verbose).run
    end

    def read_target_title
      opf_path = File.join(epub_oebps_dir, 'package.opf')
      doc = Nokogiri::XML(File.read(opf_path))
      doc.remove_namespaces!
      doc.at_xpath('//title')&.text || 'Untitled'
    end

    def detect_conflicts
      new_numbers = chapter_numbers_in(@workspace.chapters_dir)
      existing_numbers = chapter_numbers_in(epub_oebps_dir)
      conflicts = new_numbers & existing_numbers
      return if conflicts.empty?

      formatted = conflicts.sort.map { |n| n == n.to_i ? n.to_i.to_s : n.to_s }
      raise ArgumentError,
            "Chapter number conflict: chapters #{formatted.join(', ')} already exist in the target EPUB. " \
            'Renumber the source chapters or remove conflicting chapters from the target.'
    end

    def chapter_numbers_in(dir)
      Dir.glob(File.join(dir, 'chapter_*.xhtml')).filter_map do |path|
        basename = File.basename(path, '.xhtml')
        if (m = basename.match(/_(\d+)_5\z/))
          m[1].to_f + 0.5
        elsif (m = basename.match(/_(\d+)\z/))
          m[1].to_f
        end
      end
    end
  end
end
