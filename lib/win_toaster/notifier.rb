# frozen_string_literal: true

require "open3"

module WinToaster
  # Builds a Windows toast notification and shows it by invoking Windows
  # PowerShell (powershell.exe) from WSL. The toast XML and the PowerShell
  # script are Base64-encoded so that arbitrary text (including Japanese and
  # shell metacharacters) survives the WSL -> Windows boundary without any
  # quoting or injection concerns.
  class Notifier
    # Default AppUserModelId. This is Windows PowerShell's registered id, taken
    # from the reference article. Toasts shown under it appear as coming from
    # "Windows PowerShell". Override via +app_id+ to use your own.
    DEFAULT_APP_ID = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'

    # The Windows PowerShell executable, resolved from PATH inside WSL.
    POWERSHELL = "powershell.exe"

    attr_reader :title, :message, :detail, :image, :hero, :app_id

    # +image+ is shown as the small icon (appLogoOverride) and +hero+ as the
    # large banner image. Both take a file path; from WSL a Linux/WSL path
    # (e.g. /mnt/c/... or /home/...) is accepted and converted to a Windows
    # path automatically.
    def initialize(title:, message:, detail: nil, image: nil, hero: nil, app_id: DEFAULT_APP_ID)
      @title = title
      @message = message
      @detail = detail
      @image = image
      @hero = hero
      @app_id = app_id
    end

    # Builds the toast XML using the ToastGeneric template. Text nodes are
    # XML-escaped. The +detail+ line and image nodes are omitted when nil.
    def build_xml
      nodes = [title, message, detail].compact.map { |t| "<text>#{escape_xml(t)}</text>" }
      nodes << image_node("appLogoOverride", image) if image
      nodes << image_node("hero", hero) if hero
      %(<toast><visual><binding template="ToastGeneric">#{nodes.join}</binding></visual></toast>)
    end

    # The PowerShell script that decodes the XML and shows the toast.
    def powershell_script
      xml_b64 = [build_xml.encode("UTF-8")].pack("m0")
      app_id_literal = app_id.gsub("'", "''")
      <<~PS
        $ErrorActionPreference = 'Stop'
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom, ContentType = WindowsRuntime] | Out-Null
        $xmlText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('#{xml_b64}'))
        $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
        $xml.LoadXml($xmlText)
        $toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('#{app_id_literal}').Show($toast)
      PS
    end

    # The argv used to launch PowerShell with the script as an EncodedCommand.
    # Using -EncodedCommand avoids shell quoting issues and the UNC-path warning
    # that -File triggers when run from a WSL working directory.
    def powershell_command
      encoded = [powershell_script.encode("UTF-16LE")].pack("m0")
      [POWERSHELL, "-NoProfile", "-NonInteractive", "-EncodedCommand", encoded]
    end

    # Builds and shows the toast. Returns true on success and raises
    # WinToaster::Error on any failure.
    def deliver
      _stdout, stderr, status = Open3.capture3(*powershell_command)
      unless status.success?
        raise Error, "failed to show toast (exit #{status.exitstatus}): #{stderr.strip}"
      end

      true
    rescue Errno::ENOENT
      raise Error, "#{POWERSHELL} not found. win_toaster requires Windows PowerShell, " \
                   "so run it from WSL or from Ruby on Windows."
    end

    private

    def image_node(placement, path)
      %(<image placement="#{placement}" src="#{escape_xml(windows_path(path))}"/>)
    end

    # Converts a file path to a Windows path that the toast can load. From WSL,
    # `wslpath -w` maps the path (e.g. /mnt/c/... or /home/...) to its Windows
    # form. On native Windows wslpath is absent, so the absolute path is used
    # as-is.
    def windows_path(path)
      expanded = File.expand_path(path)
      out, _err, status = Open3.capture3("wslpath", "-w", expanded)
      status.success? ? out.strip : expanded
    rescue Errno::ENOENT
      expanded
    end

    def escape_xml(text)
      text.to_s
          .gsub("&", "&amp;")
          .gsub("<", "&lt;")
          .gsub(">", "&gt;")
          .gsub('"', "&quot;")
          .gsub("'", "&apos;")
    end
  end
end
