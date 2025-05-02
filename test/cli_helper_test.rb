require_relative 'test_helper'
require_relative '../lib/epub_tools/cli_helper'
require 'fileutils'
require 'stringio'

class CLIHelperTest < Minitest::Test
  def setup
    # Create a dummy command class for testing
    Object.const_set(:DummyCommand, Class.new do
      attr_reader :options

      def initialize(options = {})
        @options = options
      end

      def run
        @options
      end
    end)
    
    # Reset commands registry before each test
    EpubTools::CLIHelper.class_variable_set(:@@commands, {})
  end

  def teardown
    # Clean up the test class
    Object.send(:remove_const, :DummyCommand) if Object.const_defined?(:DummyCommand)
  end

  def test_parse_options
    options = {}
    orig_argv = ARGV.dup
    begin
      ARGV.replace(['-t', 'test title', '-a', 'test author'])
      
      EpubTools::CLIHelper.parse(options, %i[title author]) do |opts, o|
        opts.on('-t TITLE', '--title TITLE', 'Book title') { |v| o[:title] = v }
        opts.on('-a AUTHOR', '--author AUTHOR', 'Author name') { |v| o[:author] = v }
      end
      
      assert_equal 'test title', options[:title]
      assert_equal 'test author', options[:author]
    ensure
      ARGV.replace(orig_argv)
    end
  end

  def test_parse_with_missing_required_options
    options = {}
    orig_argv = ARGV.dup
    orig_stderr = $stderr
    
    begin
      ARGV.replace(['-t', 'test title'])
      $stderr = StringIO.new
      
      assert_raises(SystemExit) do
        EpubTools::CLIHelper.parse(options, %i[title author]) do |opts, o|
          opts.on('-t TITLE', '--title TITLE', 'Book title') { |v| o[:title] = v }
          opts.on('-a AUTHOR', '--author AUTHOR', 'Author name') { |v| o[:author] = v }
        end
      end
      
      assert_match(/Missing required options: --author/, $stderr.string)
    ensure
      ARGV.replace(orig_argv)
      $stderr = orig_stderr
    end
  end

  def test_add_verbose_option
    options = {}
    parser = OptionParser.new
    
    EpubTools::CLIHelper.add_verbose_option(parser, options)
    
    assert_equal true, options[:verbose], "Default verbose should be true"
    
    # Simulate passing the quiet flag
    options = {}
    parser = OptionParser.new
    
    # Mock the parser to set the option as if -q was passed
    EpubTools::CLIHelper.add_verbose_option(parser, options)
    parser.parse(['-q'])
    
    assert_equal false, options[:verbose], "Verbose should be false when -q is passed"
  end

  def test_add_input_dir_option
    options = {}
    parser = OptionParser.new
    
    EpubTools::CLIHelper.add_input_dir_option(parser, options, 'Test dir')
    parser.parse(['-i', 'test_dir'])
    
    assert_equal 'test_dir', options[:input_dir]
  end

  def test_add_output_dir_option_with_default
    options = {}
    parser = OptionParser.new
    
    EpubTools::CLIHelper.add_output_dir_option(parser, options, 'Output dir', './default')
    
    assert_equal './default', options[:output_dir], "Default should be set"
    
    # Test with providing the option
    options = {}
    parser = OptionParser.new
    
    EpubTools::CLIHelper.add_output_dir_option(parser, options, 'Output dir', './default')
    parser.parse(['-o', './custom'])
    
    assert_equal './custom', options[:output_dir], "Custom value should override default"
  end
  
  def test_register_and_handle_command
    # Register a test command
    EpubTools::CLIHelper.register_command(
      'test',
      DummyCommand,
      [:required_option],
      { default_option: 'default_value' }
    )
    
    # Check that command is registered
    assert_includes EpubTools::CLIHelper.commands, 'test'
    
    # Test handle_command with valid arguments
    orig_argv = ARGV.dup
    begin
      ARGV.replace(['-r', 'required_value'])
      
      result = EpubTools::CLIHelper.handle_command('test_prog', 'test') do |opts, options|
        opts.on('-r VAL', '--required VAL', 'Required option') { |v| options[:required_option] = v }
      end
      
      assert result, "handle_command should return true for a valid command"
    ensure
      ARGV.replace(orig_argv)
    end
  end
  
  def test_handle_command_with_invalid_command
    # Try to handle a non-registered command
    result = EpubTools::CLIHelper.handle_command('test_prog', 'nonexistent')
    
    assert_equal false, result, "handle_command should return false for an invalid command"
  end
  
  def test_command_execution
    # Create a mock command to verify it gets executed
    executed = false
    test_command = Class.new do
      define_method(:initialize) { |_| }
      define_method(:run) { executed = true }
    end
    
    # Register our command
    EpubTools::CLIHelper.register_command('execute_test', test_command)
    
    # Execute the command
    orig_argv = ARGV.dup
    begin
      ARGV.replace([])
      
      EpubTools::CLIHelper.handle_command('test_prog', 'execute_test')
      
      assert executed, "The command's run method should be called"
    ensure
      ARGV.replace(orig_argv)
    end
  end
  
  def test_add_title_and_author_options
    options = {}
    parser = OptionParser.new
    
    EpubTools::CLIHelper.add_title_option(parser, options)
    EpubTools::CLIHelper.add_author_option(parser, options)
    
    parser.parse(['-t', 'Test Title', '-a', 'Test Author'])
    
    assert_equal 'Test Title', options[:title]
    assert_equal 'Test Author', options[:author]
  end
  
  def test_add_cover_option
    options = {}
    parser = OptionParser.new
    
    EpubTools::CLIHelper.add_cover_option(parser, options)
    parser.parse(['-c', 'cover.jpg'])
    
    assert_equal 'cover.jpg', options[:cover_image]
  end
end