# frozen_string_literal: true

require_relative 'epub_tools/version'
require_relative 'epub_tools/loggable'
require_relative 'epub_tools/add_chapters'
require_relative 'epub_tools/epub_initializer'
require_relative 'epub_tools/split_chapters'
require_relative 'epub_tools/chapter_marker_detector'
require_relative 'epub_tools/xhtml_cleaner'
require_relative 'epub_tools/xhtml_extractor'
require_relative 'epub_tools/pack_ebook'
require_relative 'epub_tools/unpack_ebook'
require_relative 'epub_tools/book_builder'
require_relative 'epub_tools/compile_book'
require_relative 'epub_tools/append_book'
require_relative 'epub_tools/cli'

# Wrapper for all the other classes
module EpubTools
end
