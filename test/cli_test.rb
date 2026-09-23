# frozen_string_literal: true

require_relative 'test_helper'
require_relative '../lib/epub_tools'

class CLITest < Minitest::Test
  def test_parse_maps_flags_to_option_keys
    options = EpubTools::CLI.parse('init', %w[-t Title -a Author -o dir -c cover.jpg])

    assert_equal({ verbose: true, title: 'Title', author: 'Author', destination: 'dir', cover_image: 'cover.jpg' },
                 options)
  end

  def test_quiet_turns_off_verbose
    refute EpubTools::CLI.parse('pack', %w[-i dir -o out.epub -q])[:verbose]
  end

  def test_commands_without_verbose_output_have_no_quiet_flag
    assert_equal({ chapters_dir: 'c', oebps_dir: 'e' }, EpubTools::CLI.parse('add', %w[-c c -e e]))
    assert_output('', /invalid option: -q/) do
      assert_raises(SystemExit) { EpubTools::CLI.parse('add', %w[-c c -e e -q]) }
    end
  end

  def test_missing_required_options_name_their_flags
    assert_output('', /Missing required options: --output-dir\n/) do
      assert_raises(SystemExit) { EpubTools::CLI.parse('init', %w[-t Title -a Author]) }
    end
  end

  def test_run_builds_and_runs_the_command
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, 'mimetype'), 'application/epub+zip')
      out = File.join(dir, '..', "#{File.basename(dir)}.epub")
      command = EpubTools::CLI.run(['pack', '-i', dir, '-o', out, '-q'])

      assert_instance_of EpubTools::PackEbook, command
      assert_path_exists out
    ensure
      FileUtils.rm_f(out)
    end
  end
end
