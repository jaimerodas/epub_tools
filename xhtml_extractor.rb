#!/usr/bin/env ruby
require 'zip'
require 'fileutils'

class XHTMLExtractor
  def initialize(source_dir:, target_dir:)
    @source_dir = File.expand_path(source_dir)
    @target_dir = File.expand_path(target_dir)
    FileUtils.mkdir_p(@target_dir)
  end

  def extract_all
    epub_files.each do |epub_path|
      extract_xhtmls_from(epub_path)
    end
  end

  private

  def epub_files
    Dir.glob(File.join(@source_dir, '*.epub'))
  end

  def extract_xhtmls_from(epub_path)
    epub_name = File.basename(epub_path, '.epub')
    puts "Looking at #{epub_name}.epub"
    Zip::File.open(epub_path) do |zip_file|
      zip_file.each do |entry|
        next unless entry.name.downcase.end_with?('.xhtml')
        next if File.basename(entry.name).downcase == 'nav.xhtml'
        puts "Extracting #{entry}"
        output_path = File.join(@target_dir, "#{epub_name}_#{File.basename(entry.name)}")
        FileUtils.mkdir_p(File.dirname(output_path))
        entry.extract(output_path) { true } # overwrite if exists
      end
    end
  rescue Zip::Error => e
    warn "⚠️ Failed to process #{epub_path}: #{e.message}"
  end
end

if __FILE__ == $0
  require_relative 'cli_helper'
  options = {}
  CLIHelper.parse(options, [:source_dir, :target_dir]) do |opts, o|
    opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options]"
    opts.on('-s DIR', '--source-dir DIR', 'Directory with EPUBs to extract XHTMLs from (required)') { |v| o[:source_dir] = v }
    opts.on('-t DIR', '--target-dir DIR', 'Directory where the XHTML files will be extracted to (required)') { |v| o[:target_dir] = v }
  end

  XHTMLExtractor.new(source_dir: options[:source_dir], target_dir: options[:target_dir]).extract_all
end
