# frozen_string_literal: true

require "test_helper"

class TestWinToaster < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::WinToaster::VERSION
  end

  def test_notify_delegates_to_notifier
    captured = nil
    fake = Object.new
    fake.define_singleton_method(:deliver) { true }

    WinToaster::Notifier.stub(:new, ->(**kw) { captured = kw; fake }) do
      assert WinToaster.notify(title: "t", message: "m")
    end

    assert_equal "t", captured[:title]
    assert_equal "m", captured[:message]
  end
end
