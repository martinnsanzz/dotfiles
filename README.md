# dotfiles

My terminal setup for macOS. Opening Ghostty gives this workspace automatically:

```
┌──────────────┬──────────────┐
│              │  yazi tree   │
│   claude     │ (Enter→vim)  │
│              ├──────────────┤
│              │ fish terminal│
└──────────────┴──────────────┘
```

## Install

```sh
git clone git@github.com:martinnsanzz/dotfiles.git ~/Projects/dotfiles
~/Projects/dotfiles/install.sh
```

Then open Ghostty. `./install.sh links` only re-creates the symlinks and `./install.sh tools` only installs the tools. Any config that already exists is moved to `<name>.bak-<timestamp>` before it gets replaced.

## The tools

| Tool | What it is | Role here |
|---|---|---|
| [Ghostty](https://ghostty.org) | The terminal app. | It's the window. On launch it runs `bin/workspace`. |
| [tmux](https://github.com/tmux/tmux) | A terminal multiplexer. | Splits the window into panes. The session keeps running after Ghostty closes. |
| [yazi](https://yazi-rs.github.io) | A terminal file manager. | The file tree. Enter opens a file in vim. |
| vim | The text editor. | Editing files (`vim/vimrc`, no plugins). |
| [Claude Code](https://claude.com/claude-code) | AI coding assistant. | The left pane. |
| fish | The shell. | The bottom-right terminal. |
| Homebrew | The macOS package manager. | `install.sh` uses it to install everything. |

### How it fits together

1. Ghostty's config (`ghostty/config`) sets `command = .../workspace`, so every window runs that script instead of a plain shell.
2. `bin/workspace` creates a tmux session called `main` with three panes and types `claude` and `yazi` into two of them. If `main` already exists, it reattaches instead. That's why closing Ghostty loses nothing.
3. yazi's `edit` opener (`yazi/yazi.toml`) runs vim inside the yazi pane. Quitting vim brings the tree back.
4. `install.sh` symlinks each file in this repo to the place the app reads it from. Editing a file here changes the live config.

| Repo file | Linked to |
|---|---|
| `ghostty/config` | `~/.config/ghostty/config` |
| `tmux/tmux.conf` | `~/.config/tmux/tmux.conf` |
| `yazi/yazi.toml` | `~/.config/yazi/yazi.toml` |
| `vim/vimrc` | `~/.vimrc` |
| `bin/workspace` | `~/.local/bin/workspace` |

## Cheat sheet

### tmux (prefix = `Ctrl+b`, press it, release it, then press the key)

| Keys | Action |
|---|---|
| `Option+←↑↓→` | Move between panes (no prefix needed) |
| Mouse | Click a pane to focus it, drag a border to resize, scroll for history |
| `prefix z` | Zoom the current pane to full screen (press again to restore) |
| `prefix \|` / `prefix -` | Split side-by-side / top-bottom |
| `prefix x` | Close the current pane |
| `prefix c` | New window (tab); `prefix 1..9` switches between them |
| `prefix [` | Scroll/copy mode (`v` selects, `y` copies, `q` exits) |
| `prefix d` | Detach (session keeps running) |
| `prefix r` | Reload tmux config |

### yazi

| Keys | Action |
|---|---|
| `j`/`k` or arrows | Move down/up |
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

### Ghostty

| Keys | Action |
|---|---|
| `Cmd+Shift+R` | Reload Ghostty config |
| `Cmd+N` | New window (shares the same tmux session) |

## Troubleshooting

- **Start the layout fresh:** run `tmux kill-server`, then open a new Ghostty window.
- **A pane's program exited:** the pane falls back to a shell. Type `claude` or `yazi` to start it again.
- **Ghostty opens a plain shell:** tmux isn't installed or isn't on PATH. Run `./install.sh tools`.

## Later: moving to Neovim

Install `neovim`, add an `nvim/` folder with a link to `~/.config/nvim`, and change `vim` to `nvim` in `yazi/yazi.toml`.
