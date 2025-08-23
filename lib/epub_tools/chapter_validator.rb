# frozen_string_literal: true

require_relative 'loggable'

module EpubTools
  # Validates chapter sequence completeness
  class ChapterValidator
    include Loggable

    def initialize(chapters_dir:, verbose: false)
      @chapters_dir = chapters_dir
      @verbose = verbose
    end

    def validate
      log 'Validating chapter sequence...'
      nums = extract_chapter_numbers
      check_sequence_completeness(nums)
      log "Chapter sequence is complete: #{nums.first} to #{nums.last}."
    end

    private

    def extract_chapter_numbers
      nums = Dir.glob(File.join(@chapters_dir, '*.xhtml')).map do |file|
        if (m = File.basename(file, '.xhtml').match(/_(\d+)\z/))
          m[1].to_i
        end
      end.compact
      raise "No chapter files found in #{@chapters_dir}" if nums.empty?

      nums.sort.uniq
    end

    def check_sequence_completeness(sorted)
      missing = (sorted.first..sorted.last).to_a - sorted
      raise "Missing chapter numbers: #{missing.join(' ')}" if missing.any?
    end
  end
end
