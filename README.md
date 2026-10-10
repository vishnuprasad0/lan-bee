# LAN Bee

Chat, send files and voice messages with people on the same Wi-Fi or office
network. No server, no account, no internet: everything goes directly
between computers on your local network.

LAN Bee works with [BeeBEEP](https://www.beebeep.net) desktop, so you can
talk to colleagues who already use BeeBEEP. LAN Bee is not affiliated with
the BeeBEEP project.

## Download

Get the latest version from the
[Releases page](https://github.com/vishnuprasad0/lan-bee/releases/latest).

| Platform | File |
|---|---|
| Windows 10 (1809 or later) and 11, 64-bit | `LAN-Bee-Setup-<version>-x64.exe` (installer) |
| Windows, no install | `LAN-Bee-<version>-windows-x64-portable.zip` |
| macOS 10.15 or later (Apple Silicon and Intel) | `LAN-Bee-<version>-macos.dmg` |

An Android version is coming to Google Play.

## Install on Windows

1. Run `LAN-Bee-Setup-<version>-x64.exe`.
2. If Windows shows "Windows protected your PC", click **More info**, then
   **Run anyway**. The installer is not code-signed yet.
3. The installer allows LAN Bee through Windows Firewall on private and
   domain networks, so other people on your network can reach you.

Portable zip: unzip anywhere and run `lan_bee.exe`. When Windows Firewall
asks, allow access on **private networks**.

## Install on macOS

1. Open `LAN-Bee-<version>-macos.dmg` and drag **LAN Bee** to
   **Applications**.
2. The app is not notarized by Apple yet, so the first launch is blocked.
   Open **System Settings > Privacy & Security**, scroll down and click
   **Open Anyway** next to the LAN Bee message, then confirm.
3. Allow local network access and, for voice messages, microphone access
   when macOS asks.

## Using it

- Both computers must be on the same network (same Wi-Fi or LAN). Guest
  Wi-Fi networks often block devices from seeing each other.
- People appear under **Users** automatically. Click someone to start a
  chat.
- On a wide window the chat opens next to the list. **Enter** sends,
  **Shift+Enter** starts a new line, right click a message for actions.

## Privacy

LAN Bee has no analytics, ads or tracking. Messages and files go only to the
person you are talking to, and chat history stays on your computer.

## Problems

Open an [issue](https://github.com/vishnuprasad0/lan-bee/issues) with your
operating system, LAN Bee version, and what happened.
