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

    # Validates that integer chapter numbers form a complete sequence with no gaps.
    # Half-chapters (e.g. chapter_5_5.xhtml) are recognized but not required.
    # @raise [RuntimeError] if no chapter files are found or if integer chapters have gaps
    def validate
      log 'Validating chapter sequence...'
      nums = extract_chapter_numbers
      check_sequence_completeness(nums)
      log "Chapter sequence is complete: #{nums.first} to #{nums.last}."
    end

    private

    def extract_chapter_numbers
      nums = Dir.glob(File.join(@chapters_dir, '*.xhtml')).filter_map do |file|
        extract_chapter_number(File.basename(file, '.xhtml'))
      end
      raise "No chapter files found in #{@chapters_dir}" if nums.empty?

      nums.sort.uniq
    end

    def extract_chapter_number(basename)
      if (m = basename.match(/_(\d+)_5\z/))
        m[1].to_i + 0.5
      elsif (m = basename.match(/_(\d+)\z/))
        m[1].to_i
      end
    end

    def check_sequence_completeness(sorted)
      integers = sorted.select { |n| n == n.to_i }.map(&:to_i)
      missing = (integers.first..integers.last).to_a - integers
      raise "Missing chapter numbers: #{missing.join(' ')}" if missing.any?
    end
  end
end
