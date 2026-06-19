# frozen_string_literal: true

require_relative "win_toaster/version"

module WinToaster
  class Error < StandardError; end

  # Show a Windows toast notification from WSL.
  #
  #   WinToaster.notify(title: "Build finished", message: "All green")
  #
  # Returns true on success and raises WinToaster::Error on failure.
  def self.notify(title:, message:, detail: nil, app_id: Notifier::DEFAULT_APP_ID)
    Notifier.new(title: title, message: message, detail: detail, app_id: app_id).deliver
  end
end

require_relative "win_toaster/notifier"
