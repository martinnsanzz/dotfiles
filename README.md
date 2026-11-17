# dotfiles

My keyboard-driven terminal setup for macOS. Opening Ghostty gives this workspace automatically, with numbered tabs in the bottom bar:

```
 1:home                                2:dev
┌──────────────┬──────────────┐     ┌──────────────┬──────────────┐
│  btop        │              │     │              │  yazi tree   │
│  (CPU/RAM)   │              │     │   claude     │ (Enter→vim)  │
├──────────────┤   terminal   │     │              ├──────────────┤
│  ASCII art   │              │     │              │   terminal   │
│  + sys info  │              │     │              │              │
└──────────────┴──────────────┘     └──────────────┴──────────────┘
```

`Option+1` / `Option+2` switch tabs and `Option+h/j/k/l` move between panes. `Option+d` opens another dev tab for any project. `Option+?` shows every shortcut.

## Install

```sh
git clone git@github.com:martinnsanzz/dotfiles.git ~/Projects/dotfiles
~/Projects/dotfiles/install.sh
```

Then open Ghostty (`open -a Ghostty`). `./install.sh links` only re-creates the symlinks and `./install.sh tools` only installs the tools. Any config that already exists is moved to `<name>.bak-<timestamp>` before it gets replaced.

## The tools

| Tool | What it is | Role here |
|---|---|---|
| [Ghostty](https://ghostty.org) | The terminal app. | It's the window. On launch it runs `bin/workspace`. |
| [tmux](https://github.com/tmux/tmux) | A terminal multiplexer. | Tabs (tmux "windows") and panes. The session keeps running after Ghostty closes. |
| [yazi](https://yazi-rs.github.io) | A terminal file manager. | The file tree. Enter opens a file in vim. |
| vim | The text editor. | Editing files (`vim/vimrc`, no plugins). |
| [Claude Code](https://claude.com/claude-code) | AI coding assistant. | The left pane of each dev tab. |
| [btop](https://github.com/aristocratos/btop) | A live system monitor. | CPU, memory, disk, network and processes on the home tab. |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | A system info printer. | Draws the ASCII art next to the macOS, chip, memory and battery info. |
| [fzf](https://github.com/junegunn/fzf) | A fuzzy finder. | The project picker behind `Option+d`. |
| fish | The shell. | Every terminal pane. |
| Homebrew | The macOS package manager. | `install.sh` uses it to install everything. |

### How it fits together

1. `ghostty/config` sets `command = .../workspace`, so every Ghostty window runs that script instead of a plain shell. `macos-option-as-alt` makes the Option key work for tmux shortcuts.
2. `bin/workspace` creates the tmux session `main` with the home tab, then calls `bin/dev` to add the dev tab. If `main` already exists, it reattaches instead. That's why closing Ghostty loses nothing.
3. `bin/dev [folder]` builds a claude/tree/terminal tab. `dev --pick` shows an fzf list of `~` and the folders in `~/Projects` first.
4. `bin/home-art` picks a random file from `art/` and draws it with fastfetch. It redraws when the pane is resized.
5. yazi's `edit` opener (`yazi/yazi.toml`) runs vim inside the yazi pane. Quitting vim brings the tree back.
6. `install.sh` symlinks each file in this repo to the place the app reads it from. Editing a file here changes the live config.

| Repo file | Linked to |
|---|---|
| `ghostty/config` | `~/.config/ghostty/config` |
| `tmux/tmux.conf`, `tmux/keys.txt` | `~/.config/tmux/` |
| `yazi/yazi.toml` | `~/.config/yazi/yazi.toml` |
| `fastfetch/config.jsonc` | `~/.config/fastfetch/config.jsonc` |
| `vim/vimrc` | `~/.vimrc` |
| `bin/*` | `~/.local/bin/` |

## ASCII art

Drop any `.txt` file into `art/` to add it to the rotation. A new art is picked every time the workspace starts. To swap it without restarting, focus the art pane and press `r`.

## Cheat sheet

The same list opens with `Option+?` (in `tmux/keys.txt`). Option is the ⌥ key.

### Tabs

| Keys | Action |
|---|---|
| `Option+1..9` | Go to tab 1..9 |
| `Option+t` | New shell tab |
| `Option+d` | New dev tab (pick a project) |
| `Option+r` | Rename tab |
| `Option+Shift+w` | Close tab |

### Panes

| Keys | Action |
|---|---|
| `Option+h/j/k/l` or `Option+arrows` | Move left/down/up/right |
| `Option+Shift+h/j/k/l` | Resize |
| `Option+z` | Zoom pane to the full tab (toggle) |
| `Option+v` / `Option+s` | Split side by side / top-bottom |
| `Option+w` | Close pane |
| `Option+u` | Scroll up through history (`j/k`, `Ctrl+u/d`, `v` select, `y` copy, `q` exit) |

The mouse still works as a fallback.

### yazi

| Keys | Action |
|---|---|
| `j`/`k` | Move down/up |
| `l` / `Enter` | Open folder / open file in vim |
| `h` | Go up a folder |
| `a` | Create a file (end the name with `/` to make a folder) |
| `r` | Rename |
| `Space` | Select; `y` copy, `x` cut, `p` paste |
| `d` | Move to trash |
| `.` | Show/hide hidden files |
| `/` | Search in the folder |
| `q` | Quit (type `yazi` to reopen) |

### vim survival

| Keys | Action |
|---|---|
| `i` | Start typing (insert mode) |
| `Esc` | Back to normal mode |
| `:w` | Save |
| `:q` | Quit (`:q!` quits without saving, `:wq` saves and quits) |
| `u` / `Ctrl+r` | Undo / redo |
| `/word` | Search (`n` = next match, `Space h` clears highlighting) |
| `dd` / `yy` / `p` | Delete line / copy line / paste |

Run `vimtutor` in the terminal for a 30-minute interactive lesson.

### Other

| Keys | Action |
|---|---|
| `Ctrl+b r` | Reload tmux config |
| `Ctrl+b d` | Detach (session keeps running) |
| `Cmd+Shift+R` | Reload Ghostty config |

tmux catches these Option shortcuts before the program in the pane sees them. For example, `Option+arrows` no longer jump by word in fish, and Claude Code's own Option shortcuts that overlap won't fire. Every other Option combination still passes through.

## Troubleshooting

- **Start the layout fresh:** run `tmux kill-server`, then open a new Ghostty window.
- **A pane's program exited:** the pane falls back to a shell. Type `claude`, `yazi`, `btop` or `home-art` to start it again.
- **Ghostty opens a plain shell:** tmux isn't installed or isn't on PATH. Run `./install.sh tools`.

## Later: moving to Neovim

Install `neovim`, add an `nvim/` folder with a link to `~/.config/nvim`, and change `vim` to `nvim` in `yazi/yazi.toml`.
