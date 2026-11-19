#!/usr/bin/env bash
# Installs the tools with Homebrew and symlinks every config into place.
# Safe to re-run: existing files are moved to <name>.bak-<timestamp> first.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# nvim lives in its own repo, next to this one; a fresh machine clones it.
NVIM_CONFIG="${NVIM_CONFIG:-$(dirname "$DOTFILES")/nvim-config}"
NVIM_CONFIG_REPO="${NVIM_CONFIG_REPO:-git@github.com:martinnsanzz/nvim-config.git}"

install_tools() {
	if ! command -v brew >/dev/null 2>&1; then
		echo "Homebrew is required: https://brew.sh" >&2
		exit 1
	fi
	if [ ! -d /Applications/Ghostty.app ]; then
		brew install --cask ghostty
	fi
	# ripgrep, fd, lazygit and tree-sitter-cli are for nvim (search, git, syntax)
	for pkg in tmux yazi fish btop fzf neovim ripgrep fd lazygit tree-sitter-cli; do
		brew list --formula "$pkg" >/dev/null 2>&1 || brew install "$pkg"
	done
}

# link <file in repo> <destination>
link() {
	local src="$DOTFILES/$1" dest="$2"
	mkdir -p "$(dirname "$dest")"
	if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
		echo "ok      $dest"
		return
	fi
	if [ -e "$dest" ] || [ -L "$dest" ]; then
		local backup="$dest.bak-$(date +%Y%m%d-%H%M%S)"
		mv "$dest" "$backup"
		echo "backup  $dest -> $backup"
	fi
	ln -s "$src" "$dest"
	echo "linked  $dest"
}

# ~/.config/nvim -> the nvim-config repo (cloned first if it's missing)
link_nvim() {
	if [ ! -d "$NVIM_CONFIG" ]; then
		git clone "$NVIM_CONFIG_REPO" "$NVIM_CONFIG"
	fi
	local dest="$HOME/.config/nvim"
	if [ "$(readlink "$dest")" = "$NVIM_CONFIG" ]; then
		echo "ok      $dest"
		return
	fi
	if [ -e "$dest" ] || [ -L "$dest" ]; then
		mv "$dest" "$dest.bak-$(date +%Y%m%d-%H%M%S)"
		echo "backup  $dest"
	fi
	ln -s "$NVIM_CONFIG" "$dest"
	echo "linked  $dest"
}

# build_swift <source in repo> <command name>: compiles a small Swift program
# into ~/.local/bin with the Xcode command line tools. Skipped when the build
# is newer than the source. Prints "built" when it (re)compiled.
build_swift() {
	local src="$DOTFILES/$1" out="$HOME/.local/bin/$2"
	if ! command -v swiftc >/dev/null 2>&1; then
		echo "skip    $2 (no swiftc: run xcode-select --install)"
		return 1
	fi
	if [ -x "$out" ] && [ ! -L "$out" ] && [ "$out" -nt "$src" ]; then
		echo "ok      $out"
		return 0
	fi
	mkdir -p "$(dirname "$out")"
	swiftc -O "$src" -o "$out" && echo "built   $out"
}

# raise-windows brings windows opened from a terminal to the front. A
# LaunchAgent starts it at login and restarts it if it ever stops; it's
# reloaded here whenever the program or its plist changed.
RAISE_LABEL=com.dotfiles.raise-windows
start_raise_windows() {
	local built plist="$HOME/Library/LaunchAgents/$RAISE_LABEL.plist"
	built=$(build_swift raise-windows/raise-windows.swift raise-windows) || return 0
	echo "$built"
	local want
	want=$(cat <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key><string>$RAISE_LABEL</string>
	<key>ProgramArguments</key><array><string>$HOME/.local/bin/raise-windows</string></array>
	<key>RunAtLoad</key><true/>
	<key>KeepAlive</key><true/>
	<key>ProcessType</key><string>Interactive</string>
</dict>
</plist>
PLIST
)
	local changed=0
	if [ "$(cat "$plist" 2>/dev/null)" != "$want" ]; then
		mkdir -p "$(dirname "$plist")"
		printf '%s\n' "$want" > "$plist"
		changed=1
	fi
	case "$built" in built*) changed=1 ;; esac
	if [ "$changed" = 1 ] || ! launchctl print "gui/$(id -u)/$RAISE_LABEL" >/dev/null 2>&1; then
		launchctl bootout "gui/$(id -u)/$RAISE_LABEL" 2>/dev/null || true
		launchctl bootstrap "gui/$(id -u)" "$plist" && echo "started $RAISE_LABEL"
	else
		echo "ok      $plist (running)"
	fi
}

link_configs() {
	link ghostty/config   "$HOME/.config/ghostty/config"
	link tmux/tmux.conf   "$HOME/.config/tmux/tmux.conf"
	link tmux/keys.txt    "$HOME/.config/tmux/keys.txt"
	link yazi/yazi.toml   "$HOME/.config/yazi/yazi.toml"
	link yazi/keymap.toml "$HOME/.config/yazi/keymap.toml"
	link yazi/init.lua    "$HOME/.config/yazi/init.lua"
	link yazi/plugins/open-nvim.yazi "$HOME/.config/yazi/plugins/open-nvim.yazi"
	link yazi/plugins/quit-popup.yazi "$HOME/.config/yazi/plugins/quit-popup.yazi"
	link btop/btop.conf   "$HOME/.config/btop/btop.conf"
	link btop/themes/plain.theme "$HOME/.config/btop/themes/plain.theme"
	link_nvim
	for script in "$DOTFILES"/bin/*; do
		chmod +x "$script"
		link "bin/$(basename "$script")" "$HOME/.local/bin/$(basename "$script")"
	done
	build_swift calendar/calhelper.swift calhelper || true
	start_raise_windows
}

case "${1:-all}" in
	tools) install_tools ;;
	links) link_configs ;;
	all)   install_tools; link_configs ;;
	*)     echo "usage: $0 [tools|links]" >&2; exit 1 ;;
esac

echo "Done. Open Ghostty to start the workspace."
