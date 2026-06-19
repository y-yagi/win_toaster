# frozen_string_literal: true

require "test_helper"
require "win_toaster/cli"

class TestCLI < Minitest::Test
  def test_run_calls_notify_with_parsed_arguments
    captured = nil

    WinToaster.stub(:notify, ->(**kw) { captured = kw; true }) do
      code = WinToaster::CLI.run(["タイトル", "本文", "--detail", "詳細"])
      assert_equal 0, code
    end

    assert_equal "タイトル", captured[:title]
    assert_equal "本文", captured[:message]
    assert_equal "詳細", captured[:detail]
  end

  def test_run_returns_1_when_message_missing
    code = nil
    capture_io { code = WinToaster::CLI.run(["only-title"]) }

    assert_equal 1, code
  end

  def test_run_returns_1_on_notify_error
    code = nil

    WinToaster.stub(:notify, ->(**) { raise WinToaster::Error, "nope" }) do
      capture_io { code = WinToaster::CLI.run(["t", "m"]) }
    end

    assert_equal 1, code
  end

  def test_run_returns_0_for_version
    code = nil
    out, = capture_io { code = WinToaster::CLI.run(["--version"]) }

    assert_equal 0, code
    assert_includes out, WinToaster::VERSION
  end
end
