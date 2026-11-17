#!/usr/bin/env bash
# Installs the tools with Homebrew and symlinks every config into place.
# Safe to re-run: existing files are moved to <name>.bak-<timestamp> first.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# nvim lives in its own repo, next to this one. Set NVIM_CONFIG_REPO to the
# repo's git URL so a fresh machine can clone it.
NVIM_CONFIG="${NVIM_CONFIG:-$(dirname "$DOTFILES")/nvim-config}"
NVIM_CONFIG_REPO="${NVIM_CONFIG_REPO:-}"

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
		if [ -z "$NVIM_CONFIG_REPO" ]; then
			echo "skip    ~/.config/nvim ($NVIM_CONFIG missing; set NVIM_CONFIG_REPO to clone it)"
			return
		fi
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

link_configs() {
	link ghostty/config   "$HOME/.config/ghostty/config"
	link tmux/tmux.conf   "$HOME/.config/tmux/tmux.conf"
	link tmux/keys.txt    "$HOME/.config/tmux/keys.txt"
	link yazi/yazi.toml   "$HOME/.config/yazi/yazi.toml"
	link yazi/keymap.toml "$HOME/.config/yazi/keymap.toml"
	link yazi/init.lua    "$HOME/.config/yazi/init.lua"
	link yazi/plugins/open-vim.yazi "$HOME/.config/yazi/plugins/open-vim.yazi"
	link btop/btop.conf   "$HOME/.config/btop/btop.conf"
	link btop/themes/plain.theme "$HOME/.config/btop/themes/plain.theme"
	link vim/vimrc        "$HOME/.vimrc"
	link_nvim
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
