# WinToaster

Show native Windows toast notifications from **WSL** or **Windows**.

`win_toaster` invokes Windows PowerShell (`powershell.exe`) and uses the
`Windows.UI.Notifications` API to display a toast. It works both from WSL and
from Ruby running on Windows directly, since it only needs `powershell.exe` on
`PATH`. The notification text and the PowerShell script are Base64-encoded before
being handed to PowerShell, so non-ASCII text and shell metacharacters are passed
through safely.

## Requirements

- Windows 10 / 11 with `powershell.exe` available on `PATH`, either:
  - inside WSL (`powershell.exe` is reachable via WSL interop), or
  - on Windows directly
- Ruby >= 3.2

## Installation

Install the gem:

```bash
gem install win_toaster
```

Or add it to your `Gemfile`:

```ruby
gem "win_toaster"
```

## Usage

### Ruby

```ruby
require "win_toaster"

WinToaster.notify(title: "Build finished", message: "All tests are green")

# An optional third line, images, and a custom AppUserModelId:
WinToaster.notify(
  title:   "Deploy finished",
  message: "Production has been updated",
  detail:  "took 3m",
  image:   "/mnt/c/Users/me/Pictures/icon.png",  # small icon (appLogoOverride)
  hero:    "/mnt/c/Users/me/Pictures/banner.png", # large banner image
  app_id:  '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
)
```

`WinToaster.notify` returns `true` on success and raises `WinToaster::Error`
on failure (e.g. when `powershell.exe` cannot be found).

#### Images

`image:` is shown as the small icon (`appLogoOverride`) and `hero:` as the large
banner image. Both take a file path. From WSL you can pass a Linux/WSL path
(e.g. `/mnt/c/...` or `/home/...`); it is converted to a Windows path with
`wslpath -w` automatically. On native Windows the path is used as-is. The path
must be absolute and point to a file Windows can read; an unreadable path is
silently dropped by Windows (the rest of the toast still shows).

### CLI

```bash
win_toaster "Build finished" "All tests are green"
win_toaster "Build finished" "All green" --detail "took 3m"
win_toaster "Deploy finished" "Production updated" --image /mnt/c/Users/me/Pictures/icon.png
win_toaster --help
```

## Default AppId

When you don't pass `app_id`, win_toaster uses Windows PowerShell's AppUserModelId:

```
{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe
```

A toast can only be displayed under an AppUserModelId (AUMID) that is registered
with the system via a Start menu shortcut — `CreateToastNotifier` fails to show
the toast otherwise. Windows ships with such a shortcut for Windows PowerShell,
so this AUMID is already registered and works out of the box without you having
to register an application of your own. Notifications then appear attributed to
"Windows PowerShell". The leading GUID `{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}`
is the well-known `FOLDERID_System` known-folder id (the `System32` folder); it
is a public constant, not a secret.

To show notifications under your own app name/icon, register a custom AUMID and
pass it via `app_id:` (or `--app-id`).

References (official Microsoft docs):

- [How to enable desktop toast notifications through an AppUserModelID](https://learn.microsoft.com/en-us/windows/win32/shell/enable-desktop-toast-with-appusermodelid)
  — a Start-menu shortcut carrying an AUMID is required to raise a toast.
- [ToastNotificationManager.CreateToastNotifier](https://learn.microsoft.com/en-us/uwp/api/windows.ui.notifications.toastnotificationmanager.createtoastnotifier)
  — the API used here; the AUMID must match the shortcut or the toast is not shown.
- [KNOWNFOLDERID](https://learn.microsoft.com/en-us/windows/win32/shell/knownfolderid)
  — `FOLDERID_System` is defined as `{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}`.

## How it works

1. Builds the toast XML (`ToastGeneric` template), XML-escaping each text node.
2. Base64-encodes the XML and embeds it in a small PowerShell script.
3. Base64-encodes the whole script (UTF-16LE) and runs
   `powershell.exe -NoProfile -NonInteractive -EncodedCommand <script>`.

Using `-EncodedCommand` avoids shell-quoting problems and the UNC-path warning
that `-File` triggers when launched from a WSL working directory. The same
encoded invocation works whether PowerShell is reached through WSL interop or
run on Windows directly.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then run
`rake test` to run the tests. The test suite stubs out PowerShell, so it runs on
any platform (no `powershell.exe` required).

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/y-yagi/win_toaster.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
