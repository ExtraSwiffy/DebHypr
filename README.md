# DebHypr

### Debian 13 Trixie • Hyprland • Quickshell

DebHypr is a **minimal Debian 13 desktop environment built around Hyprland**.

It is a lightweight, clean, and keyboard-driven desktop setup designed around **Hyprland**, with **Quickshell** providing the custom desktop interface.

DebHypr focuses on keeping the system simple while still providing the things needed for a comfortable everyday desktop and gaming experience.

## Development Status

The `main` version of DebHypr is the **newest and more experimental version** of the desktop.

It is considered a higher level of testing and may contain newer features, changes, or bugs that have not yet made it into the ISO.

The **Beta 1.0.0 ISO** is considered the more stable release.

For those who want to test the current ISO development build, see the [DebHypr ISO test build](https://github.com/ExtraSwiffy/DebHypr/tree/iso-v1.0).

## Features

* **Hyprland** — Wayland compositor and tiling window manager
* **Quickshell** — Custom desktop interface
* **Hyprpaper** — Wallpaper management
* **Ghostty** — Primary terminal
* **Kitty** — Additional terminal
* **Firefox** — Web browser
* **Steam** — Gaming
* **Gamescope** — Gaming support
* **Starship** — Shell prompt
* **Fastfetch** — System information
* **PipeWire** — Audio
* **Bluetooth**
* **NetworkManager**
* Custom fonts and wallpapers
* DebHypr desktop utilities

## Keyboard Shortcuts

DebHypr uses **Super** as its main modifier.

| Shortcut           | Action              |
| ------------------ | ------------------- |
| **Super + T**      | Open Ghostty        |
| **Super + F**      | Open Firefox        |
| **Super + S**      | Open Steam          |
| **Super + M**      | Open Spotify        |
| **Super + C**      | Close active window |
| **Super + V**      | Toggle floating     |
| **Super + Delete** | Console mode        |
| **Super + Tab**    | Reboot into Windows |
| **Super + End**    | Log out             |

## Quickshell

Quickshell provides the custom DebHypr desktop interface.

It includes:

* Workspaces
* Clock
* Weather
* Media controls
* Audio information
* Desktop menus
* Wallpaper controls
* System controls
* Configuration access
* Update information

## Installation

DebHypr is intended for a Debian 13 (Trixie) installation with **Hyprland already installed**.

Clone the repository:

```bash
git clone https://github.com/ExtraSwiffy/DebHypr.git
cd ~/DebHypr
```

Run the installer:

```bash
chmod +x install.sh
./install.sh
```

After installation, reboot and log into the **Hyprland** session.

## Live ISO

The DebHypr Live ISO is developed separately from `main`.

The current ISO development build is available on the [`iso-v1.0` branch](https://github.com/ExtraSwiffy/DebHypr/tree/iso-v1.0).

The ISO branch is more controlled and stable than `main`. The current ISO development is based on the Beta 1.0 line and is being developed toward **Beta 2.0.0**.

The official released version is currently **Beta 1.0.0**.

For the stable released ISO, visit the [DebHypr Releases](https://github.com/ExtraSwiffy/DebHypr/releases) page.

## Philosophy

DebHypr is designed to be a **minimal desktop** rather than a full traditional desktop environment.

It keeps the system focused around Hyprland, a small collection of useful applications, and a custom Quickshell interface.

The goal is a clean and comfortable Debian desktop without unnecessary software or visual clutter.

**DebHypr — Debian, rebuilt my way.**
