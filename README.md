# LAN Bee

Chat, send files and voice messages with people on the same Wi-Fi or office
network. No server, no account, no internet: everything goes directly
between computers on your local network.

LAN Bee is inspired by, and works with, [BeeBEEP](https://www.beebeep.net),
so you can talk to colleagues who already use BeeBEEP on their desktop.
See [Thank you, BeeBEEP](#thank-you-beebeep).

## Download

**Android:** [Get LAN Bee on Google Play](https://play.google.com/store/apps/details?id=com.appmavens.lanbee)

**Windows and macOS:** get the latest version from the
[Releases page](https://github.com/vishnuprasad0/lan-bee/releases/latest).

| Platform | File |
|---|---|
| Windows 10 (1809 or later) and 11, 64-bit | `LAN-Bee-Setup-<version>-x64.exe` (installer) |
| Windows, no install | `LAN-Bee-<version>-windows-x64-portable.zip` |
| macOS 10.15 or later (Apple Silicon and Intel) | `LAN-Bee-<version>-macos.dmg` |
| Android | [Google Play](https://play.google.com/store/apps/details?id=com.appmavens.lanbee) |

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

## Thank you, BeeBEEP

LAN Bee would not exist without [BeeBEEP](https://www.beebeep.net). BeeBEEP
showed how simple office chat can be: no server, no account, nothing
leaving your network. That idea is the heart of LAN Bee, and we are
grateful to its developer for building it and sharing it with the world.

We made LAN Bee to bring the same experience to the places we needed it
most: the phones we all carry every day, and current Macs, including Apple
Silicon models, where we could no longer run the desktop version. LAN Bee
speaks BeeBEEP's protocol, so people on BeeBEEP desktop and people on
LAN Bee can keep talking to each other.

LAN Bee is an independent app. It is not affiliated with or endorsed by the
BeeBEEP project, and all credit for the original idea goes to BeeBEEP. If
you use BeeBEEP on your desktop, please consider supporting the project at
[beebeep.net](https://www.beebeep.net).

## Problems

Open an [issue](https://github.com/vishnuprasad0/lan-bee/issues) with your
operating system, LAN Bee version, and what happened.
