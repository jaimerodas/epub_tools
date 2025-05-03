require_relative 'test_helper'
require 'fileutils'
require 'tempfile'
require 'pathname'

class CLICommandsTest < Minitest::Test
  def setup
    @bin_path = File.expand_path('../bin/epub-tools', __dir__)
  end

  def test_show_usage_with_no_args
    output = `#{@bin_path}`

    assert_match(/Usage: epub-tools COMMAND \[options\]/, output)
    assert_match(/Commands:/, output)
    assert_includes output, 'init'
    assert_includes output, 'extract'
    assert_includes output, 'split'
    assert_includes output, 'add'
    assert_includes output, 'pack'
    assert_includes output, 'unpack'
    assert_includes output, 'compile'
  end

  def test_show_version
    output = `#{@bin_path} --version`

    assert_match(/^\d+\.\d+\.\d+$/, output.strip)

    output = `#{@bin_path} -v`

    assert_match(/^\d+\.\d+\.\d+$/, output.strip)
  end

  def test_compile_command_requires_required_options
    output = `#{@bin_path} compile 2>&1`

    assert_match(/Missing required options/, output)
  end

  def test_run_compile_command
    # Mock the execution - we won't actually run the full compile since it's complex
    # Instead we'll use the --help flag for each command to check it's available and formatted correctly
    output = `#{@bin_path} compile --help`

    assert_match(/Usage: epub-tools compile \[options\]/, output)
    assert_includes output, '--title TITLE'
    assert_includes output, '--author AUTHOR'
    assert_includes output, '--source-dir DIR'
  end

  def test_extract_command
    output = `#{@bin_path} extract --help`

    assert_match(/Usage: epub-tools extract \[options\]/, output)
    assert_includes output, '--source-dir DIR'
    assert_includes output, '--target-dir DIR'
  end

  def test_split_command
    output = `#{@bin_path} split --help`

    assert_match(/Usage: epub-tools split \[options\]/, output)
    assert_includes output, '--input FILE'
    assert_includes output, '--title TITLE'
  end

  def test_init_command
    output = `#{@bin_path} init --help`

    assert_match(/Usage: epub-tools init \[options\]/, output)
    assert_includes output, '--title TITLE'
    assert_includes output, '--author AUTHOR'
    assert_includes output, '--output-dir DIR'
  end

  def test_add_command
    output = `#{@bin_path} add --help`

    assert_match(/Usage: epub-tools add \[options\]/, output)
    assert_includes output, '--chapters-dir DIR'
    assert_includes output, '--epub-oebps-dir DIR'
  end

  def test_pack_command
    output = `#{@bin_path} pack --help`

    assert_match(/Usage: epub-tools pack \[options\]/, output)
    assert_includes output, '--input-dir DIR'
    assert_includes output, '--output-file FILE'
  end

  def test_unpack_command
    output = `#{@bin_path} unpack --help`

    assert_match(/Usage: epub-tools unpack \[options\]/, output)
    assert_includes output, '--input-file FILE'
    assert_includes output, '--output-dir DIR'
  end
end
