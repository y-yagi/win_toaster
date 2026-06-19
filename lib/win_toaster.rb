# frozen_string_literal: true

require_relative "win_toaster/version"

module WinToaster
  class Error < StandardError; end

  # Show a Windows toast notification from WSL.
  #
  #   WinToaster.notify(title: "Build finished", message: "All green")
  #
  # +image+ (small icon) and +hero+ (large banner) take a file path; from WSL a
  # Linux/WSL path is accepted and converted to a Windows path automatically.
  #
  # Returns true on success and raises WinToaster::Error on failure.
  def self.notify(title:, message:, detail: nil, image: nil, hero: nil, app_id: Notifier::DEFAULT_APP_ID)
    Notifier.new(
      title: title, message: message, detail: detail,
      image: image, hero: hero, app_id: app_id
    ).deliver
  end
end

require_relative "win_toaster/notifier"
