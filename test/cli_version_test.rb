require_relative 'test_helper'
require_relative '../lib/epub_tools/version'
require 'open3'

class CLIVersionTest < Minitest::Test
  def test_version_flag
    # Path to the CLI executable under the project root
    project_root = File.expand_path('..', __dir__)
    cli = File.join(project_root, 'bin', 'epub-tools')
    # Run with --version
    out, status = Open3.capture2(cli, '--version')
    assert_equal "#{EpubTools::VERSION}\n", out
    assert status.success?, "Expected exit status 0, got #{status.exitstatus}"

    # Run with -v
    out2, status2 = Open3.capture2(cli, '-v')
    assert_equal "#{EpubTools::VERSION}\n", out2
    assert status2.success?, "Expected exit status 0, got #{status2.exitstatus}"
  end
end