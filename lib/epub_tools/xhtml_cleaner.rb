#!/usr/bin/env ruby

require 'nokogiri'
require 'yaml'

module EpubTools
  # Cleans Google Docs XHTMLs

  # Google Docs makes a mess out of EPUBs and creates html without proper tag names and just uses
  # classes for _everything_. This class does the following to clean invalid xhtml:
  #
  # - Removes any <tt><br /></tt> or <tt><hr /></tt> tags.
  # - Removes empty <tt><p></tt> tags.
  # - Using the +class_config+, it removes <tt><span></tt> tags that are used for bold or italics and
  #   replaces them with <tt><b></tt> or <tt><i></tt> tags.
  # - Unwraps any <tt><span></tt> tags that have no classes assigned.
  # - Outputs everything to a cleanly formatted +.xhtml+
  class XHTMLCleaner
    # Initializes the class
    # @param options [Hash] Configuration options
    # @option options [String] :filename The path to the xhtml to clean (required)
    # @option options [String] :class_config Path to a YAML file containing the bold and italic classes to check
    #                          (default: 'text_style_classes.yaml')
    def initialize(options = {})
      @filename = options.fetch(:filename)
      class_config = options[:class_config] || 'text_style_classes.yaml'
      @classes = YAML.load_file(class_config).transform_keys(&:to_sym)
    end

    # Runs the cleaner
    # @return [String] Path to the cleaned file
    def run
      raw_content = read_and_strip_problematic_hr
      doc = parse_xml(raw_content)
      remove_empty_paragraphs(doc)
      remove_bold_spans(doc)
      replace_italic_spans(doc)
      unwrap_remaining_spans(doc)
      write_pretty_output(doc)
      @filename
    end

    private

    def read_and_strip_problematic_hr
      File.read(@filename).gsub(%r{<hr\b[^>]*/?>}i, '').gsub(%r{<br\b[^>]*/?>}i, '')
    end

    def parse_xml(content)
      Nokogiri::XML(content) { |config| config.default_xml.noblanks }
    rescue StandardError => e
      abort "Error parsing XML: #{e.message}"
    end

    def remove_empty_paragraphs(doc)
      doc.css('p').each do |p|
        content = p.inner_html.strip
        if content.empty? || content =~ %r{\A(<span[^>]*>\s*</span>\s*)+\z}
          p.remove
        else
          p.remove_attribute('class')
        end
      end
    end

    def remove_bold_spans(doc)
      @classes[:bolds].each do |class_name|
        doc.css("span.#{class_name}").each do |node|
          node.parent.remove
        end
      end
    end

    def replace_italic_spans(doc)
      @classes[:italics].each do |class_name|
        doc.css("span.#{class_name}").each do |node|
          node.name = 'i'
          node.remove_attribute('class')
        end
      end
    end

    def unwrap_remaining_spans(doc)
      doc.css('span').each do |span|
        span.add_next_sibling(span.dup.content)
        span.remove
      end
    end

    def write_pretty_output(doc)
      formatted_xml = doc.to_xml(indent: 2)
      File.write(@filename, formatted_xml)
    end
  end
end
