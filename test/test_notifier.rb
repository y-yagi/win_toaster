# frozen_string_literal: true

require "test_helper"

class TestNotifier < Minitest::Test
  FakeStatus = Struct.new(:ok, :exitstatus) do
    def success? = ok
  end

  def test_build_xml_escapes_special_characters
    xml = WinToaster::Notifier.new(title: "A & B", message: "<tag>", detail: '"q"').build_xml

    assert_includes xml, "<text>A &amp; B</text>"
    assert_includes xml, "<text>&lt;tag&gt;</text>"
    assert_includes xml, "<text>&quot;q&quot;</text>"
  end

  def test_build_xml_omits_detail_when_nil
    xml = WinToaster::Notifier.new(title: "t", message: "m").build_xml

    assert_equal 2, xml.scan("<text>").size
  end

  def test_build_xml_includes_detail_when_present
    xml = WinToaster::Notifier.new(title: "t", message: "m", detail: "d").build_xml

    assert_equal 3, xml.scan("<text>").size
  end

  def test_powershell_command_uses_encoded_command
    cmd = WinToaster::Notifier.new(title: "t", message: "m").powershell_command

    assert_equal "powershell.exe", cmd[0]
    assert_includes cmd, "-EncodedCommand"
    assert_includes decode_script(cmd), "CreateToastNotifier"
  end

  def test_japanese_round_trips_through_base64
    cmd = WinToaster::Notifier.new(title: "こんにちは", message: "日本語テスト").powershell_command
    script = decode_script(cmd)

    xml_b64 = script[/FromBase64String\('([^']+)'\)/, 1]
    xml = xml_b64.unpack1("m").force_encoding("UTF-8")

    assert_includes xml, "こんにちは"
    assert_includes xml, "日本語テスト"
  end

  def test_app_id_single_quotes_are_escaped
    cmd = WinToaster::Notifier.new(title: "t", message: "m", app_id: "a'b").powershell_command

    assert_includes decode_script(cmd), "CreateToastNotifier('a''b')"
  end

  def test_deliver_returns_true_on_success
    notifier = WinToaster::Notifier.new(title: "t", message: "m")

    Open3.stub(:capture3, ["", "", FakeStatus.new(true, 0)]) do
      assert notifier.deliver
    end
  end

  def test_deliver_raises_on_failure
    notifier = WinToaster::Notifier.new(title: "t", message: "m")

    Open3.stub(:capture3, ["", "boom", FakeStatus.new(false, 1)]) do
      error = assert_raises(WinToaster::Error) { notifier.deliver }
      assert_includes error.message, "boom"
    end
  end

  def test_deliver_raises_when_powershell_missing
    notifier = WinToaster::Notifier.new(title: "t", message: "m")

    Open3.stub(:capture3, ->(*) { raise Errno::ENOENT }) do
      error = assert_raises(WinToaster::Error) { notifier.deliver }
      assert_includes error.message, "powershell.exe"
    end
  end

  private

  def decode_script(cmd)
    cmd.last.unpack1("m").force_encoding("UTF-16LE").encode("UTF-8")
  end
end
