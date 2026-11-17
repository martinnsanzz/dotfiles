#!/usr/bin/env bash
# Installs the tools with Homebrew and symlinks every config into place.
# Safe to re-run: existing files are moved to <name>.bak-<timestamp> first.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_tools() {
	if ! command -v brew >/dev/null 2>&1; then
		echo "Homebrew is required: https://brew.sh" >&2
		exit 1
	fi
	if [ ! -d /Applications/Ghostty.app ]; then
		brew install --cask ghostty
	fi
	for pkg in tmux yazi fish btop fastfetch fzf; do
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

link_configs() {
	link ghostty/config   "$HOME/.config/ghostty/config"
	link tmux/tmux.conf   "$HOME/.config/tmux/tmux.conf"
	link tmux/keys.txt    "$HOME/.config/tmux/keys.txt"
	link yazi/yazi.toml   "$HOME/.config/yazi/yazi.toml"
	link fastfetch/config.jsonc "$HOME/.config/fastfetch/config.jsonc"
	link vim/vimrc        "$HOME/.vimrc"
	for script in "$DOTFILES"/bin/*; do
		chmod +x "$script"
		link "bin/$(basename "$script")" "$HOME/.local/bin/$(basename "$script")"
	done
}

case "${1:-all}" in
	tools) install_tools ;;
	links) link_configs ;;
	all)   install_tools; link_configs ;;
	*)     echo "usage: $0 [tools|links]" >&2; exit 1 ;;
esac

echo "Done. Open Ghostty to start the workspace."
