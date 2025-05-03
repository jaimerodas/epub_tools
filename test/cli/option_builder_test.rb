require_relative '../test_helper'
require_relative '../../lib/epub_tools'
require 'stringio'

class OptionBuilderTest < Minitest::Test
  def setup
    @builder = EpubTools::CLI::OptionBuilder.new
  end

  def test_initialize_with_defaults
    builder = EpubTools::CLI::OptionBuilder.new({ default: 'value' }, [:required])

    assert_equal({ default: 'value' }, builder.options)
    assert_equal [:required], builder.required_keys
  end

  def test_with_banner
    @builder.with_banner('Test Banner')
    assert_equal 'Test Banner', @builder.parser.banner
  end

  def test_with_help_option
    # This test is tricky as --help would exit, so we'll test indirectly
    @builder.with_help_option
    assert_includes @builder.parser.to_s, '-h, --help'
  end

  def test_with_verbose_option
    @builder.with_verbose_option

    assert_equal true, @builder.options[:verbose]

    # Parse args with --quiet to change verbose to false
    @builder.parse(['--quiet'])
    assert_equal false, @builder.options[:verbose]
  end

  def test_with_input_file
    @builder.with_input_file('Test input')

    assert_includes @builder.parser.to_s, '-i, --input-file FILE'
    assert_includes @builder.parser.to_s, 'Test input (required)'

    # Test with required=false
    builder2 = EpubTools::CLI::OptionBuilder.new
    builder2.with_input_file('Test input', false)
    assert_includes builder2.parser.to_s, 'Test input'
    refute_includes builder2.parser.to_s, 'Test input (required)'

    # Test with actual parsing
    @builder.parse(['-i', 'file.txt'])
    assert_equal 'file.txt', @builder.options[:input_file]
  end

  def test_with_input_dir
    @builder.with_input_dir('Test input dir')

    assert_includes @builder.parser.to_s, '-i, --input-dir DIR'
    assert_includes @builder.parser.to_s, 'Test input dir (required)'

    @builder.parse(['-i', 'dir/path'])
    assert_equal 'dir/path', @builder.options[:input_dir]
  end

  def test_with_output_dir
    # Test with default value
    @builder.with_output_dir('Test output dir', 'default/path')

    assert_includes @builder.parser.to_s, '-o, --output-dir DIR'
    assert_includes @builder.parser.to_s, 'Test output dir (default: default/path)'
    assert_equal 'default/path', @builder.options[:output_dir]

    # Test without default
    builder2 = EpubTools::CLI::OptionBuilder.new
    builder2.with_output_dir('Test output dir')
    assert_includes builder2.parser.to_s, 'Test output dir (required)'

    # Test actual parsing
    @builder.parse(['-o', 'new/path'])
    assert_equal 'new/path', @builder.options[:output_dir]
  end

  def test_with_output_file
    @builder.with_output_file('Test output file')

    assert_includes @builder.parser.to_s, '-o, --output-file FILE'
    assert_includes @builder.parser.to_s, 'Test output file (required)'

    @builder.parse(['-o', 'output.txt'])
    assert_equal 'output.txt', @builder.options[:output_file]
  end

  def test_with_title_option
    @builder.with_title_option

    assert_includes @builder.parser.to_s, '-t, --title TITLE'
    assert_includes @builder.parser.to_s, 'Book title (required)'

    @builder.parse(['-t', 'Book Title'])
    assert_equal 'Book Title', @builder.options[:title]
  end

  def test_with_author_option
    @builder.with_author_option

    assert_includes @builder.parser.to_s, '-a, --author AUTHOR'
    assert_includes @builder.parser.to_s, 'Author name (required)'

    @builder.parse(['-a', 'Author Name'])
    assert_equal 'Author Name', @builder.options[:author]
  end

  def test_with_cover_option
    @builder.with_cover_option

    assert_includes @builder.parser.to_s, '-c, --cover PATH'
    assert_includes @builder.parser.to_s, 'Cover image file path (optional)'

    @builder.parse(['-c', 'cover.jpg'])
    assert_equal 'cover.jpg', @builder.options[:cover_image]
  end

  def test_with_option
    @builder.with_option('-x', '--extra VALUE', 'Extra option', :extra_option)

    assert_includes @builder.parser.to_s, '-x, --extra VALUE'
    assert_includes @builder.parser.to_s, 'Extra option'

    @builder.parse(['-x', 'extra-value'])
    assert_equal 'extra-value', @builder.options[:extra_option]
  end

  def test_with_custom_options
    @builder.with_custom_options do |opts, options|
      opts.on('-c', '--custom VALUE', 'Custom option') { |v| options[:custom] = v }
    end

    assert_includes @builder.parser.to_s, '-c, --custom VALUE'
    assert_includes @builder.parser.to_s, 'Custom option'

    @builder.parse(['-c', 'custom-value'])
    assert_equal 'custom-value', @builder.options[:custom]
  end

  def test_parse_validates_required_keys
    builder = EpubTools::CLI::OptionBuilder.new({}, [:required_option])
    assert_output('', /Missing required options/) do
      assert_raises(SystemExit) { builder.parse([]) }
    end
  end

  def test_method_chaining
    result = @builder.with_banner('Test')
                     .with_verbose_option
                     .with_title_option

    assert_equal @builder, result
  end
end
