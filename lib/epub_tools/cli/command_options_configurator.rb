# frozen_string_literal: true

module EpubTools
  module CLI
    # Handles command-specific option configuration for CLI commands
    class CommandOptionsConfigurator
      # Configure command-specific options using dynamic dispatch
      # @param cmd [String] Command name
      # @param builder [OptionBuilder] Option builder instance
      def configure(cmd, builder)
        method_name = "configure_#{cmd.tr('-', '_')}_options"
        raise ArgumentError, "Unknown command: #{cmd}" unless respond_to?(method_name, true)

        send(method_name, builder)
      end

      private

      # Configure options for the 'add' command
      # @param builder [OptionBuilder] Option builder instance
      def configure_add_options(builder)
        builder.with_custom_options do |opts, options|
          opts.on('-c DIR', '--chapters-dir DIR', 'Chapters directory (required)') { |v| options[:chapters_dir] = v }
          opts.on('-e DIR', '--oebps-dir DIR', 'EPUB OEBPS directory (required)') { |v| options[:oebps_dir] = v }
        end
      end

      # Configure options for the 'extract' command
      # @param builder [OptionBuilder] Option builder instance
      def configure_extract_options(builder)
        builder.with_custom_options do |opts, options|
          opts.on('-s DIR', '--source-dir DIR', 'Directory with EPUBs to extract XHTMLs from (required)') do |v|
            options[:source_dir] = v
          end
          opts.on('-t DIR', '--target-dir DIR',
                  'Directory where the XHTML files will be extracted to (required)') do |v|
            options[:target_dir] = v
          end
        end.with_verbose_option
      end

      # Configure options for the 'split' command
      # @param builder [OptionBuilder] Option builder instance
      def configure_split_options(builder)
        builder.with_custom_options do |opts, options|
          add_split_input_options(opts, options)
          add_split_output_options(opts, options)
        end.with_verbose_option
      end

      def add_split_input_options(opts, options)
        opts.on('-i FILE', '--input FILE', 'Source XHTML file (required)') { |v| options[:input_file] = v }
        opts.on('-t TITLE', '--title TITLE', 'Book title for HTML <title> tags (required)') do |v|
          options[:book_title] = v
        end
      end

      def add_split_output_options(opts, options)
        opts.on('-o DIR', '--output-dir DIR',
                "Output directory for chapter files (default: #{options[:output_dir]})") do |v|
          options[:output_dir] = v
        end
        opts.on('-p PREFIX', '--prefix PREFIX', "Filename prefix for chapters (default: #{options[:prefix]})") do |v|
          options[:prefix] = v
        end
      end

      # Configure options for the 'init' command
      # @param builder [OptionBuilder] Option builder instance
      def configure_init_options(builder)
        builder.with_title_option
               .with_author_option
               .with_custom_options do |opts, options|
          opts.on('-o DIR', '--output-dir DIR', 'Destination EPUB directory (required)') do |v|
            options[:destination] = v
          end
        end.with_cover_option
      end

      # Configure options for the 'pack' command
      # @param builder [OptionBuilder] Option builder instance
      def configure_pack_options(builder)
        builder.with_input_dir('EPUB directory to package')
               .with_output_file('Output EPUB file path')
               .with_verbose_option
      end

      # Configure options for the 'unpack' command
      # @param builder [OptionBuilder] Option builder instance
      def configure_unpack_options(builder)
        builder.with_custom_options do |opts, options|
          opts.on('-i FILE', '--input-file FILE', 'EPUB file to unpack (required)') { |v| options[:epub_file] = v }
          opts.on('-o DIR', '--output-dir DIR', 'Output directory to extract into (default: basename of epub)') do |v|
            options[:output_dir] = v
          end
        end.with_verbose_option
      end

      # Configure options for the 'compile' command
      # @param builder [OptionBuilder] Option builder instance
      def configure_compile_options(builder)
        builder.with_title_option
               .with_author_option
               .with_custom_options do |opts, options|
          opts.on('-s DIR', '--source-dir DIR', 'Directory with EPUBs to extract XHTMLs from (required)') do |v|
            options[:source_dir] = v
          end
          opts.on('-o FILE', '--output FILE', 'EPUB to create (default: book title in source dir)') do |v|
            options[:output_file] = v
          end
        end.with_cover_option.with_verbose_option
      end
    end
  end
end
