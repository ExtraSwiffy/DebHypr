# DebHypr Beta 1.0.0

Dev Note: Waybar is being replaced with quickshell its staying inside the guide until its complete.

A personal Debian 13 (Trixie) Hyprland desktop restore setup.

DebHypr is designed to make rebuilding my Debian 13 Hyprland desktop as simple and repeatable as possible.

This README is a complete start-to-finish installation guide.

It assumes you are starting with a completely fresh Debian 13 (Trixie) installation with no desktop environment installed.

The goal is to start at the Debian installer and finish with the complete DebHypr desktop.

---

# Complete Installation Guide

## Part 1 — Install Debian 13 Trixie

Start by installing a fresh copy of Debian 13 (Trixie).

During the Debian installation:

1. Create your normal user account.
2. Set a root password.
3. Configure your network.
4. Install the standard system utilities.
5. Do **not** install GNOME.
6. Do **not** install KDE Plasma.
7. Do **not** install XFCE.
8. Do **not** install another desktop environment.

A minimal installation with a TTY is recommended.

After Debian finishes installing, reboot.

You should eventually reach something similar to:

```text
Debian GNU/Linux 13 debian tty1

debian login:
```

Log in with the normal user account you created during installation.

---

## Part 2 — Become Root

For the initial system configuration, become root:

```bash
su -
```

Enter the root password you created during Debian installation.

You should now have a root shell.

Verify:

```bash
whoami
```

It should return:

```text
root
```

---

## Part 3 — Configure Debian Repositories

Debian 13 uses the `.sources` repository format.

Check the existing configuration:

```bash
cat /etc/apt/sources.list.d/debian.sources
```

A normal Debian 13 configuration should contain the main Debian repositories.

If necessary, create or replace the file:

```bash
nano /etc/apt/sources.list.d/debian.sources
```

Use:

```text
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie trixie-updates
Components: main contrib non-free non-free-firmware

Types: deb
URIs: http://deb.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
```

Save the file.

Update the package lists:

```bash
apt update
```

---

## Part 4 — Enable Debian Backports

DebHypr uses Debian 13 Backports for newer desktop software such as Hyprland and Gamescope.

Create:

```bash
nano /etc/apt/sources.list.d/debian-backports.sources
```

Put:

```text
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie-backports
Components: main contrib non-free non-free-firmware
```

Save the file.

Update:

```bash
apt update
```

Verify Backports:

```bash
apt-cache policy
```

You should see `trixie-backports` listed.

---

## Part 5 — Install sudo

Still logged in as root, install sudo:

```bash
apt install -y sudo
```

Add your normal user to the sudo group.

Replace `YOUR_USERNAME` with your actual Debian username:

```bash
usermod -aG sudo YOUR_USERNAME
```

For example:

```bash
usermod -aG sudo swiffy
```

Verify:

```bash
groups YOUR_USERNAME
```

You should see:

```text
sudo
```

Exit the root shell:

```bash
exit
```

Then reboot:

```bash
sudo reboot
```

Log back into your normal user account.

---

## Part 6 — Verify sudo

Test:

```bash
sudo whoami
```

Enter your password when prompted.

The result should be:

```text
root
```

If that works, continue.

---

## Part 7 — Install Git

Install Git:

```bash
sudo apt install -y git
```

Verify:

```bash
git --version
```

---

## Part 8 — Install Hyprland

Install Hyprland from Debian Trixie Backports:

```bash
sudo apt install -y -t trixie-backports hyprland
```

Verify:

```bash
hyprland --version
```

---

## Part 9 — Install Wayland and Desktop Dependencies

Install the required Wayland/session components:

```bash
sudo apt install -y \
    dbus-user-session \
    pipewire \
    pipewire-pulse \
    wireplumber \
    xwayland
```

These provide the user session, audio system, PulseAudio compatibility, session management, and X11 application compatibility required by the desktop.

---

## Part 10 — Install SDDM

Install the display manager:

```bash
sudo apt install -y sddm
```

If Debian asks which display manager should be used, select:

```text
sddm
```

Enable SDDM:

```bash
sudo systemctl enable sddm
```

Start it:

```bash
sudo systemctl start sddm
```

You should now have an SDDM login screen.

If SDDM does not immediately appear, reboot:

```bash
sudo reboot
```

---

# Part 11 — Clone DebHypr

Log into your normal user account.

Clone the repository:

```bash
git clone https://github.com/ExtraSwiffy/DebHypr.git
```

Enter the repository:

```bash
cd ~/DebHypr
```

Verify:

```bash
ls
```

You should see something similar to:

```text
assets
config
scripts
.gitignore
README.md
install.sh
```

---

# Part 12 — Make the Installer Executable

Run:

```bash
chmod +x install.sh
```

Verify:

```bash
ls -l install.sh
```

The file should have executable permissions.

---

# Part 13 — Run the DebHypr Installer

Run:

```bash
./install.sh
```

The installer backs up existing configuration files before installing the DebHypr configuration.

It installs the software and configuration used by the desktop.

---

# Part 14 — What DebHypr Installs

The DebHypr installer is intended to configure the following desktop components:

- Hyprland configuration
- Hyprpaper
- Waybar
- Ghostty
- Firefox
- Fastfetch
- Starship
- Steam
- Gamescope
- Bluetooth support
- Brightness control
- FZF
- NetworkManager
- Desktop notifications
- Media controls
- Fonts
- Windows reboot helper
- Console Mode scripts

The installer also installs the DebHypr configuration files into the appropriate user configuration directories.

---

# Part 15 — Reboot

After the installer finishes successfully:

```bash
sudo reboot
```

---

# Part 16 — First Hyprland Login

At the SDDM login screen:

1. Select your user.
2. Select the Hyprland session if necessary.
3. Log in.

You should enter the DebHypr Hyprland desktop.

The expected desktop is a minimal dark floating environment with:

- Hyprland
- Waybar
- Hyprpaper
- Ghostty
- Firefox
- Steam
- Starship
- Fastfetch

---

# Part 17 — Verify Waybar

Waybar should start automatically.

If it does not appear, test:

```bash
waybar
```

If Waybar launches manually, check the Hyprland configuration:

```bash
grep -n "waybar" ~/.config/hypr/hyprland.conf
```

The configuration should contain:

```ini
exec-once = waybar
```

---

# Part 18 — Verify Hyprpaper

Hyprpaper should also start automatically.

Check:

```bash
pgrep hyprpaper
```

If it is running, the wallpaper service is active.

The Hyprland configuration should contain:

```ini
exec-once = hyprpaper
```

---

# Part 19 — Keyboard Shortcuts

DebHypr uses Super as the main modifier.

## Applications

| Shortcut | Action |
|---|---|
| Super + F | Firefox |
| Super + S | Steam |
| Super + M | Spotify |
| Super + T | Ghostty |

## Window Controls

| Shortcut | Action |
|---|---|
| Super + C | Close active window |
| Super + V | Toggle floating |

## Console Mode

| Shortcut | Action |
|---|---|
| Super + Delete | Enter Console Mode |

## Windows

| Shortcut | Action |
|---|---|
| Super + Tab | Reboot into Windows |

## Logout

| Shortcut | Action |
|---|---|
| Super + End | Log out |

## Audio

The keyboard volume controls are handled through WirePlumber/wpctl.

---

# Part 20 — Console Mode

DebHypr includes a console-style Steam/Gamescope mode.

The shortcut is:

```text
Super + Delete
```

This launches the DebHypr Console Mode script.

Console Mode is intended to provide a Steam Deck-style fullscreen interface while still using the normal Debian installation.

The main components are:

- Gamescope
- Steam
- Steam Gamepad UI

The console resolution is intended for:

```text
2560x1440 @ 144Hz
```

The main Console Mode scripts are:

```text
~/.local/bin/start-console-after-hyprland
~/.local/bin/desktop-to-console
~/.local/bin/console-mode-session
```

---

# Part 21 — Steam

Verify Steam is installed:

```bash
steam
```

The first launch may require Steam to update itself.

After Steam finishes updating, sign into your Steam account.

DebHypr uses the normal Debian Steam package.

---

# Part 22 — Gamescope

Gamescope is installed from Debian Trixie Backports.

Verify:

```bash
gamescope --version
```

If it is installed correctly, the command should return the Gamescope version.

You can also check:

```bash
apt-cache policy gamescope
```

The installed version should come from:

```text
trixie-backports
```

---

# Part 23 — Reboot Into Windows

DebHypr includes a helper for rebooting directly into Windows.

The helper is installed as:

```text
/usr/local/sbin/reboot-to-windows
```

The Hyprland shortcut is:

```text
Super + Tab
```

The command uses the Windows boot entry configured on the machine.

Check:

```bash
sudo -n /usr/local/sbin/reboot-to-windows
```

Do not run this command unless you actually want to reboot into Windows.

---

# Part 24 — Windows Configuration

The Windows reboot helper depends on the GRUB Windows boot entry.

The DebHypr configuration currently uses the machine-specific Windows entry:

```text
osprober-efi-24E5-3B1F
```

This identifier is specific to the current installation.

If DebHypr is installed on a different machine, the Windows boot identifier may be different.

Check the available GRUB entries with:

```bash
sudo grep -R "osprober" /boot/grub/grub.cfg
```

If the Windows entry differs, update:

```text
scripts/sbin/reboot-to-windows
```

before using the Windows shortcut.

---

# Part 25 — Monitor Configuration

DebHypr is currently designed around a:

```text
2560x1440
```

display.

The primary display is expected to run at:

```text
144Hz
```

Check connected displays:

```bash
hyprctl monitors
```

This will show the monitor name, resolution, refresh rate, and position.

---

# Part 26 — Resolution and Refresh Rate

If your monitor does not automatically use the intended refresh rate, check available modes:

```bash
hyprctl monitors all
```

You can also use:

```bash
xrandr
```

for X11-compatible display information.

The current DebHypr configuration is designed around:

```text
2560x1440 @ 144Hz
```

If you use a different monitor, update the relevant Hyprland and Hyprpaper configuration.

---

# Part 27 — Starship

DebHypr uses Starship for the shell prompt.

Verify:

```bash
starship --version
```

The shell configuration should initialize Starship.

Start a new Ghostty terminal after installation.

You should see the DebHypr terminal prompt.

---

# Part 28 — Fonts

DebHypr uses modern programming fonts and emoji fonts.

The repository contains:

```text
assets/fonts/GoogleSansCode
```

The Waybar configuration uses:

```text
GoogleSansCode Nerd Font
```

After installing fonts, refresh the font cache:

```bash
fc-cache -fv
```

Verify the font:

```bash
fc-list | grep -i "Google Sans Code"
```

---

# Part 29 — Audio

DebHypr uses PipeWire and WirePlumber.

Check PipeWire:

```bash
systemctl --user status pipewire
```

Check WirePlumber:

```bash
systemctl --user status wireplumber
```

Check available audio devices:

```bash
wpctl status
```

The volume shortcuts use:

```bash
wpctl
```

---

# Part 30 — Bluetooth

Bluetooth support is installed through BlueZ.

Check:

```bash
systemctl status bluetooth
```

If necessary:

```bash
sudo systemctl enable --now bluetooth
```

Check the Bluetooth controller:

```bash
bluetoothctl
```

Inside bluetoothctl:

```text
power on
show
```

Exit:

```text
quit
```

---

# Part 31 — NetworkManager

DebHypr uses NetworkManager.

Check:

```bash
systemctl status NetworkManager
```

If necessary:

```bash
sudo systemctl enable --now NetworkManager
```

NetworkManager can also be inspected using:

```bash
nmcli
```

---

# Part 32 — Complete Installation Verification

After installation, verify the important components.

Run:

```bash
hyprland --version
```

```bash
waybar --version
```

```bash
hyprpaper --version
```

```bash
ghostty --version
```

```bash
fastfetch --version
```

```bash
starship --version
```

```bash
steam
```

```bash
gamescope --version
```

Check the configuration:

```bash
ls ~/.config/hypr
ls ~/.config/waybar
ls ~/.config/ghostty
ls ~/.config/hyprpaper
```

Check the DebHypr scripts:

```bash
ls ~/.local/bin
```

Check the Windows helper:

```bash
ls -l /usr/local/sbin/reboot-to-windows
```

---

# Part 33 — Troubleshooting

## Hyprland does not start

Check the installed version:

```bash
hyprland --version
```

Check the user session:

```bash
systemctl --user status
```

Try launching Hyprland manually from a TTY:

```bash
Hyprland
```

---

## SDDM does not appear

Check:

```bash
systemctl status sddm
```

Enable it:

```bash
sudo systemctl enable sddm
```

Start it:

```bash
sudo systemctl start sddm
```

---

## Waybar does not appear

Run:

```bash
waybar
```

If it reports a configuration problem, inspect:

```bash
~/.config/waybar
```

Also check:

```bash
hyprctl reload
```

---

## Wallpaper does not appear

Check:

```bash
pgrep hyprpaper
```

Try:

```bash
hyprpaper
```

Then inspect:

```bash
~/.config/hypr/hyprpaper.conf
```

Make sure the monitor name matches:

```bash
hyprctl monitors
```

---

## Steam does not launch

Run:

```bash
steam
```

If Steam is missing:

```bash
sudo apt install steam
```

---

## Gamescope does not launch

Check:

```bash
gamescope --version
```

If it is missing:

```bash
sudo apt install -t trixie-backports gamescope
```

---

## Windows shortcut does not work

Check:

```bash
ls -l /usr/local/sbin/reboot-to-windows
```

Check sudo permission:

```bash
sudo -n /usr/local/sbin/reboot-to-windows
```

Check the sudoers file:

```bash
sudo cat /etc/sudoers.d/debhypr-reboot-to-windows
```

Validate it:

```bash
sudo visudo -cf /etc/sudoers.d/debhypr-reboot-to-windows
```

---

# Part 34 — Updating DebHypr

To update an existing DebHypr installation:

```bash
cd ~/DebHypr
```

Pull the latest repository changes:

```bash
git pull
```

Make sure the installer is executable:

```bash
chmod +x install.sh
```

Run it:

```bash
./install.sh
```

Then reboot:

```bash
sudo reboot
```

---

# Part 35 — Repository Structure

The repository is organized approximately like this:

```text
DebHypr/
├── assets/
│   └── fonts/
│       └── GoogleSansCode/
├── config/
│   ├── ghostty/
│   ├── hypr/
│   ├── hyprpaper/
│   ├── starship/
│   └── waybar/
├── scripts/
│   └── sbin/
│       └── reboot-to-windows
├── .gitignore
├── README.md
└── install.sh
```

The goal is to keep the repository readable and make each component easy to restore or modify independently.

---

# Part 36 — Complete Fresh Debian Flow

For a completely fresh installation, the overall process is:

### 1. Install Debian 13

Install Debian 13 Trixie without a desktop environment.

### 2. Log into the TTY

```text
debian login:
```

### 3. Become root

```bash
su -
```

### 4. Configure Debian repositories

Configure:

```text
/etc/apt/sources.list.d/debian.sources
```

and:

```text
/etc/apt/sources.list.d/debian-backports.sources
```

### 5. Update packages

```bash
apt update
```

### 6. Install sudo

```bash
apt install -y sudo
```

### 7. Add your user to sudo

```bash
usermod -aG sudo YOUR_USERNAME
```

### 8. Reboot

```bash
exit
sudo reboot
```

### 9. Verify sudo

```bash
sudo whoami
```

### 10. Install Git

```bash
sudo apt install -y git
```

### 11. Install Hyprland

```bash
sudo apt install -y -t trixie-backports hyprland
```

### 12. Install Wayland/session dependencies

```bash
sudo apt install -y \
    dbus-user-session \
    pipewire \
    pipewire-pulse \
    wireplumber \
    xwayland
```

### 13. Install SDDM

```bash
sudo apt install -y sddm
```

### 14. Clone DebHypr

```bash
git clone https://github.com/ExtraSwiffy/DebHypr.git
```

### 15. Enter the repository

```bash
cd ~/DebHypr
```

### 16. Run the installer

```bash
chmod +x install.sh
./install.sh
```

### 17. Reboot

```bash
sudo reboot
```

### 18. Log into Hyprland

Select Hyprland from SDDM.

### 19. Verify the desktop

Check Waybar, Hyprpaper, Ghostty, Steam, Gamescope, audio, Bluetooth, and the Windows reboot helper.

At this point the DebHypr installation should be complete.

---

# Part 37 — Quick Install Reference

For an experienced user, the basic flow is:

```bash
su -
```

Configure Debian repositories and Backports.

```bash
apt update
apt install -y sudo
usermod -aG sudo YOUR_USERNAME
exit
sudo reboot
```

After reboot:

```bash
sudo apt install -y git
sudo apt install -y -t trixie-backports hyprland
sudo apt install -y \
    dbus-user-session \
    pipewire \
    pipewire-pulse \
    wireplumber \
    xwayland
sudo apt install -y sddm
```

Clone DebHypr:

```bash
git clone https://github.com/ExtraSwiffy/DebHypr.git
cd ~/DebHypr
chmod +x install.sh
./install.sh
```

Reboot:

```bash
sudo reboot
```

Log into Hyprland through SDDM.

---

# Part 38 — Updating the GitHub Repository

When making changes to DebHypr:

```bash
cd ~/DebHypr
```

Check the changes:

```bash
git status
```

Review the diff:

```bash
git diff
```

Check for whitespace problems:

```bash
git diff --check
```

Stage changes:

```bash
git add .
```

Commit:

```bash
git commit -m "Update DebHypr configuration"
```

Push:

```bash
git push
```

Verify:

```bash
git status
```

A clean repository should report:

```text
nothing to commit, working tree clean
```

---

# DebHypr Philosophy

DebHypr is intentionally minimal.

The goal is not to recreate a large desktop environment.

The goal is to have:

- A clean Debian base
- Hyprland
- A modern dark interface
- Floating windows
- Minimal visual clutter
- Fast keyboard-driven controls
- A clean terminal
- A functional Waybar
- Native Linux gaming
- Steam Console Mode
- Easy Windows rebooting
- Reproducible configuration

The repository exists so the entire desktop can be rebuilt without manually remembering every configuration step.

---

# Repository

GitHub:

https://github.com/ExtraSwiffy/DebHypr

Clone:

```bash
git clone https://github.com/ExtraSwiffy/DebHypr.git
```

---

# Final Result

A successful installation should result in:

```text
Debian 13 Trixie
        │
        ▼
      SDDM
        │
        ▼
    Hyprland
        │
        ├── Waybar
        ├── Hyprpaper
        ├── Ghostty
        ├── Firefox
        ├── Steam
        ├── Gamescope
        ├── Starship
        ├── Bluetooth
        ├── PipeWire
        └── DebHypr scripts
```

The intended result is a complete, reproducible Debian 13 Hyprland desktop that can be restored from a fresh installation using this repository.

