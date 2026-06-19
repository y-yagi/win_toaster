# frozen_string_literal: true

require "optparse"
require_relative "../win_toaster"

module WinToaster
  # Command-line front-end for win_toaster.
  #
  #   win_toaster TITLE MESSAGE [--detail DETAIL] [--app-id APP_ID]
  class CLI
    # Runs the CLI and returns the process exit code.
    def self.run(argv)
      new.run(argv)
    end

    def run(argv)
      options = { detail: nil, image: nil, hero: nil, app_id: Notifier::DEFAULT_APP_ID }

      parser = OptionParser.new do |o|
        o.banner = "Usage: win_toaster TITLE MESSAGE [options]"
        o.on("-d", "--detail DETAIL", "Third line shown below the message") { |v| options[:detail] = v }
        o.on("-i", "--image PATH", "Icon image (appLogoOverride)") { |v| options[:image] = v }
        o.on("--hero PATH", "Hero (large banner) image") { |v| options[:hero] = v }
        o.on("-a", "--app-id APP_ID", "AppUserModelId the toast is shown under") { |v| options[:app_id] = v }
        o.on("-v", "--version", "Show version and exit") do
          puts WinToaster::VERSION
          return 0
        end
        o.on("-h", "--help", "Show this help and exit") do
          puts o
          return 0
        end
      end

      title, message = parser.parse(argv)

      if title.nil? || message.nil?
        warn parser.banner
        return 1
      end

      WinToaster.notify(
        title: title, message: message, detail: options[:detail],
        image: options[:image], hero: options[:hero], app_id: options[:app_id]
      )
      0
    rescue OptionParser::ParseError, WinToaster::Error => e
      warn "win_toaster: #{e.message}"
      1
    end
  end
end
