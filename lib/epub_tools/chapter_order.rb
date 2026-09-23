# frozen_string_literal: true

module EpubTools
  # Reading order of chapter files: chapter_1, chapter_1_5, chapter_1a, chapter_1b, chapter_2
  module ChapterOrder
    module_function

    # @param filename [String] A chapter filename, e.g. +chapter_12a.xhtml+
    # @return [Array] A key that sorts chapter filenames in reading order
    def sort_key(filename)
      basename = File.basename(filename, '.xhtml')
      if (m = basename.match(/_(\d+)_5\z/))
        [m[1].to_f + 0.5, '']
      else
        [basename[/\d+/].to_f, basename[/\d+([a-z]*)\z/, 1].to_s]
      end
    end

    # Inserts +node+ into +parent+ before the first chapter that sorts after +filename+, so a chapter added
    # later (e.g. 12a after 13 is already in the book) still lands in reading order.
    # @yield [element] Each existing child element; returns the filename it points to
    def insert(parent, node, filename)
      key = sort_key(filename)
      later = parent.element_children.find do |el|
        href = yield(el)
        href&.start_with?('chapter_') && (sort_key(href) <=> key) == 1
      end
      later ? later.add_previous_sibling(node) : parent.add_child(node)
    end
  end
end
