# Caelestia launcher for Ryoku

Ryoku, with Caelestia's launcher: a panel that grows up out of the bottom frame
border, a list with Caelestia's sliding highlight and row animations, and a pill
search bar on the lip. Every Ryoku search provider still works (apps, `/`
actions, `=` calc, `?` web, clipboard, files, packages, media...).

## Install (on a machine already running Ryoku)

```bash
git clone https://github.com/khamsakamal48/ryoku-caelestia-launcher
cd ryoku-caelestia-launcher
./install.sh
```

Then press **Super+Space**. Switch launchers any time in Ryoku Settings →
App Launcher ("Caelestia", "Hero", "Main", "OkShell").

On a fresh Arch box, install Ryoku first, either from the Ryoku ISO or on
existing Arch with:

```bash
curl -fsSL https://raw.githubusercontent.com/ryoku-dev/ryoku-arch/main/ryoku-shell-installer/install.sh | bash
```

Ryoku needs UEFI, so a VM must boot in UEFI mode (e.g. OVMF in virt-manager).

## Update

```bash
git pull && ./install.sh
```

The installer is safe to re-run. It copies itself to
`~/.local/share/caelestia-ryoku` (the copy the pacman hook uses), so a pull
takes effect only once you run `./install.sh` again.

## Remove

```bash
~/.local/share/caelestia-ryoku/install.sh --uninstall
```

## How it works

- **New files** (the launcher UI and the launcher-variant bridge) go into
  Ryoku's update-safe overlay, `~/.config/ryoku/user_edits/quickshell/...`.
  `ryoku materialize` lays that overlay over the shipped shell on every update.
- **Two shipped files are forked by patching**:
  - `modules/bar/FrameMenuManager.qml` registers the `caelestia-launcher` frame
    surface.
  - `modules/bar/FrameSurface.qml` mounts the launcher body and uses Caelestia's
    open curve.
  - `launcher/catalog.json` gets the "Caelestia" entry, added with `jq`.
- **After every `ryoku-desktop` upgrade**, a pacman hook
  (`/etc/pacman.d/hooks/ryoku-caelestia-launcher.hook`) re-patches the new
  files, so Ryoku's own fixes to them still reach you.
  - If an update changes those files so much that the patch no longer applies,
    the forks are removed, Ryoku's Hero launcher comes back, and you get a
    notification.
  - Fix the patch in `patches/`, then run
    `~/.local/share/caelestia-ryoku/install.sh --refresh` and pick Caelestia
    again in Settings.
- **Existing overrides are respected.** If you already keep your own override of
  either frame file, the installer stops and asks you to merge the patch by hand.
  It never overwrites your file.

## Not included

- **Caelestia's own pickers:** the wallpaper and colour-scheme pickers depend on
  caelestia-cli. Use Ryoku's `/` actions and Super+W instead.
- **Hero-only extras:** the rest dashboard, the Rashin `\` ask panel and the
  Ctrl+K action sheet. Switch to Hero if you want those.
- **Other bar styles:** with a non-default bar style (qsbar or folder), Ryoku
  folds the bottom anchor onto the bar's edge, so the launcher may drop from the
  top.
