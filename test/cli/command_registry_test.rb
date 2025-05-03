require_relative '../test_helper'
require_relative '../../lib/epub_tools'

class CommandRegistryTest < Minitest::Test
  class DummyCommand
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      true
    end
  end

  def setup
    @registry = EpubTools::CLI::CommandRegistry.new
  end

  def test_registry_initializes_empty
    assert_empty @registry.commands
    assert_empty @registry.available_commands
  end

  def test_register_command
    @registry.register('test', DummyCommand, [:required_option], { default: 'value' })

    assert_equal 1, @registry.commands.size
    assert_includes @registry.available_commands, 'test'

    command = @registry.get('test')

    assert_equal DummyCommand, command[:class]
    assert_equal [:required_option], command[:required_keys]
    assert_equal({ default: 'value' }, command[:default_options])
  end

  def test_register_multiple_commands
    @registry.register('test1', DummyCommand)
    @registry.register('test2', DummyCommand)

    assert_equal 2, @registry.commands.size
    assert_includes @registry.available_commands, 'test1'
    assert_includes @registry.available_commands, 'test2'
  end

  def test_get_nonexistent_command
    assert_nil @registry.get('nonexistent')
  end

  def test_command_exists
    @registry.register('test', DummyCommand)

    assert @registry.command_exists?('test')
    refute @registry.command_exists?('nonexistent')
  end

  def test_chained_registration
    result = @registry.register('test1', DummyCommand)
                      .register('test2', DummyCommand)

    assert_equal @registry, result
    assert_equal 2, @registry.commands.size
  end
end
