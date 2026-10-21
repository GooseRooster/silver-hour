# silver-hour &nbsp; [![bluebuild build badge](https://github.com/gooserooster/silver-hour/actions/workflows/build.yml/badge.svg)](https://github.com/gooserooster/silver-hour/actions/workflows/build.yml)

An immutable, image-based Fedora Silverblue for the GNOME desktop, with a
userland built on **Nix, Home Manager and Homebrew**. silver-hour keeps the
stable, secure, atomic GNOME base and layers on a focused set of desktop
changes plus an updater that tells you when to restart.

It ships in two flavours sharing one base:

| Flavour | Image | What it is |
| --- | --- | --- |
| **workstation** | `ghcr.io/gooserooster/silver-hour-workstation` | Daily-driver GNOME desktop with Ghostty, Bazaar and the Nix/Home Manager/Homebrew userland. |
| **gaming** | `ghcr.io/gooserooster/silver-hour-gaming` | Everything in workstation plus Steam, Wine/Faugus, MangoHud/Gamescope, ProtonPlus/Protontricks, a TuneD latency profile and GPU Screen Recorder tuned for gaming. |

## What's inside

- **Atomic Fedora Silverblue** (GNOME), built on BlueBuild's `fedora-silverblue`
  base with full codecs and hardware acceleration.
- **Ghostty** as the default terminal, presented simply as **Terminal**
  (matching GNOME's own terminal icon and name). The stock terminals are
  removed and Nautilus gets a single "Open in Terminal" context entry
  (Ghostty's bundled extension is relabelled and reused).
- **Bazaar** as the app store (GNOME Software removed), with the Bazaar
  companion extension for "App Details"/"Uninstall" integration.
- **Caffeine** as a system Shell extension: it keeps the session awake (and
  activates automatically for fullscreen apps).
- **Serigy** as a system Flatpak: a minimal clipboard manager (pin and re-copy
  what you need). It is *not* started automatically — launching it is left to
  the user, since a clipboard manager sees everything you copy. System Flatpaks
  are (re)installed shortly after each boot, so it appears a moment after the
  first login.
- **VS Code** (official Microsoft build) plus a curated developer CLI baseline
  (`direnv`, `zoxide`, `git-lfs`, `git-delta`, `yq`, `hyperfine`, `tokei`,
  `pipx`, `uv`, `httpie`, `sqlite`, container tooling). Telemetry and background
  updates are disabled; language toolchains deliberately stay in
  Nix/Homebrew/a distrobox.
- **GPU Screen Recorder** for screenshots and recording, with a small GNOME
  Shell extension providing interactive region selection so the GPU path is
  preserved.
- **Update notifications and a tray indicator**: staged bootc updates are
  detected, notified, and shown in the status tray with a "restart to apply"
  action. Staging is detected with an unprivileged `ostree` probe, so a queued
  deployment shows up within seconds - no matter whether topgrade, a manual
  `sudo bootc upgrade` or the automatic updater staged it.
- **Nix + flakes** with a persistent store (`/nix` backed by `/var/nix`), and
  **Home Manager** applied per user for the dotfiles layer.
- **Homebrew** (Linuxbrew), **zsh** as the login shell, and **topgrade** to
  update the OS, Flatpaks and Homebrew in one run.
- A small baseline of CLI tools (`bat`, `fd`, `ripgrep`, `eza`, `jq`, `yq`,
  `ncdu`, `btop`, `gh`, …) and Nerd Fonts, so a fresh account is useful before
  Home Manager runs.

### Gaming flavour

- Native **Steam**, **Wine** + winetricks and **Faugus Launcher**. The Wine
  GUI entries are left out of the app grid (see the gaming notes).
- **ProtonPlus** (compatibility-tool manager) and **Protontricks** as system
  Flatpaks, alongside a curated general-purpose set of gaming utilities:
  **MangoHud** (with a shipped default `MangoHud.conf`), **Gamescope**,
  **steam-devices** (controller udev rules) and **vulkan-tools**.
- A `game-performance` helper that switches to a latency power profile while a
  game runs; idle inhibition is handled by Caffeine for fullscreen apps.
- The gaming flavour maps the power-profiles-daemon `performance` profile to
  TuneD's `latency-performance`.

#### Gaming notes

- **Wine**: the image installs the Wine components (`wine-core`,
  `wine-common`, `wine-pulseaudio`, `wine-winefonts`, `wine-mono`,
  `wine-dxvk`, …) but *not* Fedora's `wine-desktop` subpackage, which is
  where every Wine GUI entry lives (`wine`, `winecfg`, `wineboot`,
  `notepad`, `winemine`, the "Wine" app-grid menu, …). `wine` and
  `winetricks` are on `PATH` as usual; `winetricks`'s own launcher entry is
  hidden with `NoDisplay=true`. Want the entries back? Install
  `wine-desktop` in a toolbox (`dnf install wine-desktop`) or layer it.
- **MangoHud**: launch a game with `mangohud %command%` (or `MANGOHUD=1
  %command%`) in Steam, or tick MangoHud in Faugus. Toggle the overlay in-game
  with `RightShift+F12`. The shipped default lives at
  `/usr/share/MangoHud/MangoHud.conf`; copy it to
  `~/.config/MangoHud/MangoHud.conf` to customise.
- **Protontricks** runs inside a Flatpak sandbox. Steam libraries in the
  default locations (`~/.local/share/Steam`, `~/.steam`) are already
  accessible. For a library on another drive or a non-standard path, grant it
  once with:

  ```sh
  flatpak override --user --filesystem=/path/to/SteamLibrary \
    com.github.Matoking.protontricks
  ```

- **xone** (the out-of-tree Xbox wireless-adapter driver) is deliberately
  **not** included: it is a kernel module, and this image cannot sign it with
  the Secure Boot MOK key the base image uses, so it would fail to load with
  Secure Boot enabled. In-kernel `xpad` already covers wired and Bluetooth Xbox
  controllers. If you need xone, disable Secure Boot (or enrol your own MOK
  key) and layer it yourself.

## Installation

> [!WARNING]
> This is an experimental feature. Rebase at your own discretion.

Pick a flavour and rebase an existing atomic Fedora installation to it.

1. Rebase to the unsigned image first, so the signing policy is installed:

   ```sh
   bootc switch ghcr.io/gooserooster/silver-hour-workstation:latest
   ```

   (replace `workstation` with `gaming` for the gaming flavour)

2. Reboot:

   ```sh
   systemctl reboot
   ```

3. Rebase to the signed image:

   ```sh
   bootc switch --enforce-container-sigpolicy ghcr.io/gooserooster/silver-hour-workstation:latest
   ```

4. Reboot again to complete the installation.

The `latest` tag always points at the newest build, which still tracks the
Fedora version pinned in the recipe, so you won't be moved to a new major
release by accident.

## ISO

An offline ISO can be generated from a local recipe using the Silverblue
installer variant:

```sh
bluebuild generate-iso --iso-name silver-hour-workstation.iso \
  --variant silverblue recipe recipes/workstation.yml
# or: just iso workstation
```

ISOs are large, so they aren't distributed via GitHub.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s
[cosign](https://github.com/sigstore/cosign). Verify with the `cosign.pub` in
this repo:

```sh
cosign verify --key cosign.pub ghcr.io/gooserooster/silver-hour-workstation
```

## Secure Boot

silver-hour is built on BlueBuild's `fedora-silverblue` base, which signs the
kernel and kernel modules with **BlueBuild's own MOK key**
(`akmods-blue-build.der`) rather than Fedora's. If Secure Boot is enabled and
the key is not enrolled, the image **will not boot**. The enrollment password
is **`bluebuild`**.

- **Installing from an ISO:** the ISO enrolls the key during installation. On
  first boot, choose **Enroll MOK** in the shim manager and enter `bluebuild`.
- **Installing by rebasing:** enroll the key yourself after rebasing:

  ```sh
  sudo mokutil --timeout -1
  sudo mokutil --import /etc/pki/akmods/certs/akmods-blue-build.der
  # enter "bluebuild" as the one-time password, then reboot
  ```

This is **separate** from cosign verification: cosign signs the OCI image for
`bootc` signature policy; the MOK key is what UEFI Secure Boot verifies at boot.

## Building locally

```sh
nix develop            # BlueBuild CLI + podman/buildah + qemu + just
just build workstation # or: bluebuild build recipes/workstation.yml
just build-root workstation && just disk workstation && just vm-disk workstation
just iso workstation   # build the offline ISO from a published image
```

## Known messages

### `mount: (hint) your fstab has been modified…`

This line can appear (sometimes on every boot) on bootc/composefs systems. It
comes from util-linux's `mount`: it is printed when `/etc/fstab` is newer than
systemd's loaded-unit snapshot (`/run/systemd/systemd-units-load`). During early
boot the base image's bootc generator runs `bootc-fstab-edit.service`, which
adds `ro` to the `/` entry in `/etc/fstab` so `systemd-remount-fs` matches the
read-only composefs root. That edit happens after systemd has already generated
its unit tree, so any later `mount` call (podman, distrobox, flatpak, nix, …)
prints the hint. The fstab change itself is correct and the message is
harmless; it is being addressed upstream in bootc/anaconda/systemd. No action is
needed.

## Userland

Home Manager is applied per user against the dotfiles repo; the image ships
system-wide Nix with a persistent store and Homebrew, and seeds a default
`topgrade` configuration. `silver-hour-topgrade` runs topgrade in a login shell
so Homebrew is on `PATH`. Run `blujust` to list the update helpers
(`silver-hour-update-status`, `silver-hour-staged-probe`,
`silver-hour-test-update`, `silver-hour-clear-update`).

## Updates

The updater is built from three signals, cheapest first:

- **Staged deployment** - `silver-hour-staged-deployment` runs
  `ostree admin status --json` and looks for a deployment carrying the
  `staged` flag. It works unprivileged and costs a few milliseconds, so the
  tray indicator and the notifier see a queued deployment within seconds of it
  being staged - by topgrade, by a manual `sudo bootc upgrade`, or by the
  automatic updater.
- **Local status** - `silver-hour-update-status --local` (root) records the
  booted and staged deployment, including the version, in
  `/run/silver-hour/update-status.json`. It only reads local state and runs
  every five minutes.
- **Upstream availability** - the same script without `--local` also runs
  `bootc upgrade --check`, which fetches the upstream manifest. That costs a
  few seconds and a registry round trip, so it only runs every fifteen
  minutes.

`silver-hour-topgrade` refreshes the status right after topgrade finishes, so
a deployment staged by topgrade is visible right away. The status file is
world-readable: the tray indicator and the notification service read it as an
unprivileged user.
