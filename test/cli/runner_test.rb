require_relative '../test_helper'
require_relative '../../lib/epub_tools'
require 'stringio'

class RunnerTest < Minitest::Test
  class TestCommand
    attr_reader :options, :run_called

    def initialize(options)
      @options = options
      @run_called = false
    end

    def run
      @run_called = true
      puts 'Called!'
      true
    end
  end

  def setup
    @runner = EpubTools::CLI::Runner.new('test-program')

    # Register a test command
    @runner.registry.register('test-cmd', TestCommand,
                              [:required_option],
                              { default_option: 'default' })
  end

  def test_initialize
    assert_equal 'test-program', @runner.program_name
    assert_kind_of EpubTools::CLI::CommandRegistry, @runner.registry
  end

  def test_handle_command
    assert_output(/Usage: test-program test-cmd/) do
      assert_raises(SystemExit) { @runner.handle_command('test-cmd', ['-h']) }
    end
  end

  def test_handle_command_with_required_args
    runner = EpubTools::CLI::Runner.new('test-program')
    runner.registry.register('test-cmd', TestCommand)
    assert_output("Called!\n") { assert runner.handle_command('test-cmd') }
  end

  def test_handle_nonexistent_command
    result = @runner.handle_command('nonexistent')
    refute result # Should return false for nonexistent command
  end

  def test_run_with_version_flag
    assert_output(/^\d+\.\d+\.\d+$/) do
      assert_raises(SystemExit) { @runner.run(['-v']) }
    end
  end

  def test_run_with_no_args_shows_usage
    assert_output(/Usage: test-program COMMAND \[options\]/) do
      assert_raises(SystemExit) { @runner.run([]) }
    end
  end

  def test_program_name_defaults_to_current_program
    default_runner = EpubTools::CLI::Runner.new
    assert_equal File.basename($PROGRAM_NAME), default_runner.program_name
  end

  def test_configure_command_options
    # This is testing a private method, which is generally not recommended,
    # but it's useful to ensure all command configurations work

    # Use send to access private method
    builder = EpubTools::CLI::OptionBuilder.new

    # Test each command configuration - we'll just check one example
    @runner.send(:configure_command_options, 'add', builder)

    # Check add command options were added
    assert_includes builder.parser.to_s, '--chapters-dir DIR'
    assert_includes builder.parser.to_s, '--epub-oebps-dir DIR'
  end

  def test_run_with_unknown_command
    assert_output(/Usage: test-program COMMAND \[options\]/) do
      assert_raises(SystemExit) { @runner.run(['unknown-command']) }
    end
  end
end
