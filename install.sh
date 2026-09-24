#!/usr/bin/env bash
# Caelestia launcher for Ryoku.
#
#   ./install.sh               install (run as your user, not root)
#   ./install.sh --refresh     re-patch against the current Ryoku shell (pacman hook)
#   ./install.sh --uninstall   remove it and go back to Ryoku's Hero launcher
#
# Everything lands in Ryoku's update-safe overlay (~/.config/ryoku/user_edits);
# `ryoku materialize` lays it over the shipped shell. Two shipped files are
# forked by patching the *current* base, so every Ryoku update re-derives them.
set -euo pipefail

src=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
cfg=${XDG_CONFIG_HOME:-$HOME/.config}
base=/usr/share/ryoku/config/quickshell/shell/modules
ov=$cfg/ryoku/user_edits/quickshell/shell/modules
live=$cfg/quickshell/shell/modules
launcher_json=$cfg/ryoku/launcher.json
payload=${XDG_DATA_HOME:-$HOME/.local/share}/caelestia-ryoku
hook=/etc/pacman.d/hooks/ryoku-caelestia-launcher.hook
marker="caelestia-ryoku overlay"

new_files=(
    bar/popouts/CaelestiaAnim.qml
    bar/popouts/CaelestiaLauncher.qml
    bar/popouts/CaelestiaResultItem.qml
    bar/popouts/CaelestiaResultList.qml
    launcher/variants/caelestia/Main.qml
    launcher/variants/caelestia/Preview.qml
)
forks=(bar/FrameMenuManager.qml bar/FrameSurface.qml)

say() { echo "caelestia-ryoku: $*" >&2; }
die() { say "$*"; exit 1; }

notify() {
    say "$1"
    DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus} \
        notify-send -a "Caelestia launcher" "Caelestia launcher" "$1" 2>/dev/null || true
}

set_variant() {
    local tmp
    tmp=$(mktemp)
    if [[ -s $launcher_json ]]; then
        jq --arg v "$1" '.variant = $v' "$launcher_json" > "$tmp"
    else
        jq -n --arg v "$1" '{variant: $v}' > "$tmp"
    fi
    mkdir -p "$(dirname "$launcher_json")"
    mv "$tmp" "$launcher_json"
}

current_variant() {
    jq -r '.variant // ""' "$launcher_json" 2>/dev/null || true
}

# Refuse to overwrite a fork the user made themselves.
check_foreign_forks() {
    local f
    for f in "${forks[@]}"; do
        if [[ -e $ov/$f ]] && ! grep -q "$marker" "$ov/$f"; then
            die "$ov/$f is your own override; merge patches/${f##*/}.patch into it by hand"
        fi
    done
}

remove_forks() {
    local f
    for f in "${forks[@]}"; do rm -f "$ov/$f"; done
    rm -f "$ov/launcher/catalog.json"
}

# Patch fresh copies of the current base; all-or-nothing.
build_forks() {
    local tmp f
    tmp=$(mktemp -d)
    for f in "${forks[@]}"; do
        cp "$base/$f" "$tmp/${f##*/}"
        if ! patch --quiet --forward "$tmp/${f##*/}" < "$payload/patches/${f##*/}.patch"; then
            rm -rf "$tmp"
            return 1
        fi
    done
    jq '.variants |= (map(select(.id != "caelestia")) + [{
            id: "caelestia",
            name: "Caelestia",
            description: "Caelestia-style list that grows out of the bottom frame border.",
            entrypoint: "variants/caelestia/Main.qml",
            preview: "variants/caelestia/Preview.qml",
            capabilities: []
        }])' "$base/launcher/catalog.json" > "$tmp/catalog.json" || { rm -rf "$tmp"; return 1; }

    mkdir -p "$ov/bar" "$ov/launcher"
    for f in "${forks[@]}"; do mv "$tmp/${f##*/}" "$ov/$f"; done
    mv "$tmp/catalog.json" "$ov/launcher/catalog.json"
    rm -rf "$tmp"
}

copy_new_files() {
    local f
    for f in "${new_files[@]}"; do
        install -Dm644 "$payload/overlay/quickshell/shell/modules/$f" "$ov/$f"
    done
}

refresh() {
    [[ -d $base ]] || die "Ryoku shell not found at $base"
    check_foreign_forks
    copy_new_files
    if build_forks; then
        say "patched the current Ryoku shell"
    else
        remove_forks
        [[ $(current_variant) == caelestia ]] && set_variant hero
        notify "This Ryoku update changed the frame code; the Caelestia launcher is off and Hero is back. Update the patches, then run $payload/install.sh --refresh."
    fi
    ryoku materialize >/dev/null
}

install_all() {
    [[ $EUID -ne 0 ]] || die "run as your user, not root (sudo is used only for the pacman hook)"
    command -v ryoku >/dev/null || die "ryoku not found: install Ryoku first"
    [[ -d $base ]] || die "Ryoku shell not found at $base"
    command -v jq >/dev/null || sudo pacman -S --needed --noconfirm jq
    command -v patch >/dev/null || sudo pacman -S --needed --noconfirm patch
    check_foreign_forks

    # Keep a stable copy for the pacman hook, wherever this folder lives.
    if [[ $src != "$payload" ]]; then
        rm -rf "$payload"
        mkdir -p "$payload"
        cp -r "$src/install.sh" "$src/overlay" "$src/patches" "$src/ryoku-caelestia-launcher.hook" "$payload/"
    fi

    copy_new_files
    build_forks || die "patches do not apply to this Ryoku version (see patches/)"
    set_variant caelestia

    sed -e "s|@USER@|$(id -un)|" -e "s|@HOME@|$HOME|" -e "s|@SCRIPT@|$payload/install.sh|" \
        "$payload/ryoku-caelestia-launcher.hook" | sudo install -Dm644 /dev/stdin "$hook"

    ryoku materialize
    ryoku reload
    say "done: press Super+Space"
}

uninstall_all() {
    local f
    for f in "${new_files[@]}"; do rm -f "$ov/$f" "$live/$f"; done
    rmdir "$ov/launcher/variants/caelestia" "$live/launcher/variants/caelestia" 2>/dev/null || true
    for f in "${forks[@]}"; do
        if [[ -e $ov/$f ]] && grep -q "$marker" "$ov/$f"; then rm -f "$ov/$f"; fi
    done
    rm -f "$ov/launcher/catalog.json"
    [[ $(current_variant) == caelestia ]] && set_variant hero
    sudo rm -f "$hook"
    ryoku materialize
    ryoku reload
    [[ $src == "$payload" ]] || rm -rf "$payload"
    say "removed"
}

case "${1:-}" in
    "") install_all ;;
    --refresh) refresh ;;
    --uninstall) uninstall_all ;;
    *) die "usage: $0 [--refresh|--uninstall]" ;;
esac
