# dotfiles

My keyboard-driven terminal setup for macOS. Opening Ghostty gives this workspace automatically, in a slightly see-through window with numbered tabs in the top bar. It starts with just the home tab, which can't be closed:

```
 1 home
┌─────────┬───────────┬──────────────┐
│ sysinfo │  procs    │   terminal   │
│ cpu/mem │ apps and  │              │
│ + specs │ services  │              │
├─────────┴───────────┴──────────────┤
│  animated art             ⌥ keys   │
│                                    │
└────────────────────────────────────┘
```

- **sysinfo** (`bin/sysinfo`): the Mac's model, chip, macOS version, RAM, uptime and IP, plus live CPU (total, per core and a history line), load, memory, disk and battery.
- **procs** (`bin/procs`): the open apps (what the Dock shows, with their helper processes counted in) and, on the second tab, every other process. Select one and press `x` to force quit it (`t` asks it to quit nicely). It refuses to kill what keeps the workspace alive (tmux, Ghostty, loginwindow).

`Option+arrows` move between panes and `Option+?` shows every shortcut.

Two more kinds of tab open on a project picker (`~` and the folders in `~/Projects`). Each tab is named after its project, like `claude:dotfiles` or `developer:libasm`:

```
 2 claude:dotfiles
┌──────────────┬──────────────┐
│              │  yazi tree   │
│   claude     │ (Enter→nvim) │
│              ├──────────────┤
│              │   terminal   │
└──────────────┴──────────────┘
```

- `Option+c` opens a **claude** tab (above) for any folder in `~/Projects`.
- `Option+d` opens a **developer** tab, for working on Codam projects. The tree, the terminal and nvim all start in that project. nvim shows "waiting for a file" until you pick one in the tree. After that, each file you pick opens as a new tab in that same nvim.

```
 3 developer:libasm
┌──────────┬───────────────────┐
│yazi tree │                   │
│          │       nvim        │
├──────────┤ (waiting for file │
│ terminal │  until you pick)  │
└──────────┴───────────────────┘
```

## Install

```sh
git clone git@github.com:martinnsanzz/dotfiles.git ~/Projects/Claude/dotfiles
~/Projects/Claude/dotfiles/install.sh
```

Then open Ghostty (`open -a Ghostty`). `./install.sh links` only re-creates the symlinks and `./install.sh tools` only installs the tools. Any config that already exists is moved to `<name>.bak-<timestamp>` before it gets replaced.

## The tools

| Tool | What it is | Role here |
|---|---|---|
| [Ghostty](https://ghostty.org) | The terminal app. | It's the window. On launch it runs `bin/workspace`. |
| [tmux](https://github.com/tmux/tmux) | A terminal multiplexer. | Tabs (tmux "windows") and panes. The session keeps running after Ghostty closes. |
| [yazi](https://yazi-rs.github.io) | A terminal file manager. | The file tree. Enter or a click opens a file in nvim. |
| [Neovim](https://neovim.io) | The text editor. | Set up like VS Code, in its own repo: [nvim-config](../nvim-config). `vim/vimrc` stays for plain `vim`. |
| [Claude Code](https://claude.com/claude-code) | AI coding assistant. | The left pane of each claude tab. |
| [btop](https://github.com/aristocratos/btop) | A live system monitor. | Not on the home tab any more; run `btop` for the full view (plain gray/blue theme). |
| [fzf](https://github.com/junegunn/fzf) | A fuzzy finder. | The project picker behind `Option+c` and `Option+d`. |
| fish | The shell. | Every terminal pane. |
| Homebrew | The macOS package manager. | `install.sh` uses it to install everything. |

### How it fits together

1. `ghostty/config` sets `command = .../workspace`, so every Ghostty window runs that script instead of a plain shell. `macos-option-as-alt` makes the Option key work for tmux shortcuts, and `background-opacity` makes the window see-through.
2. `bin/workspace` creates the tmux session `main` with only the home tab. If `main` already exists, it reattaches instead. That's why closing Ghostty loses nothing. It marks home with the tmux option `@locked`: `Option+x`/`Option+w` in `tmux.conf` refuse to close a locked tab (or its last pane), and a pane whose shell exits there gets a fresh shell instead of closing.
3. `bin/dev claude [folder]` builds a claude/tree/terminal tab, and `bin/dev developer [folder]` builds a tree/terminal/nvim tab. With `--pick` it first shows an fzf list of `~` and the folders in `~/Projects`.
4. In a developer tab the editor pane runs `bin/dev-editor`, which shows the waiting screen. The first file you pick starts nvim there, listening on a socket named after the pane. Later picks are sent through that socket (`nvim --remote`) and open as new tabs; quitting nvim brings the waiting screen back.
5. `bin/home-art` plays looping ASCII animations across the bottom of the home tab, with the main shortcuts boxed in its top-right corner. It's Python (curses, standard library only), using the `python3` that comes with the Xcode command line tools.
6. `bin/sysinfo` and `bin/procs` fill the top-left of home. Both are Python curses like `home-art`. sysinfo reads CPU ticks straight from the kernel, procs reads `ps` and `lsappinfo` every 2 seconds. `btop/btop.conf` is kept for running btop by hand.
7. yazi's `open-vim` plugin (`yazi/plugins/`, bound in `yazi/keymap.toml` and `yazi/init.lua`) opens files with `bin/yazi-vim`. In a claude tab it swaps nvim into the tree's pane right away, and quitting nvim brings the tree back. In a developer tab it sends the file to the nvim pane on the right. (yazi's built-in way of running an editor in its pane takes about 5 seconds to start.)
8. `bin/flash` shows a short message in a centered tmux popup. `Ctrl+b r` uses it to confirm the tmux config reloaded. Ghostty's `Cmd+Shift+R` reloads Ghostty and then types a private key code that tmux binds (`User0`) to the same popup.
9. `install.sh` symlinks each file in this repo to the place the app reads it from. Editing a file here changes the live config.

| Repo file | Linked to |
|---|---|
| `ghostty/config` | `~/.config/ghostty/config` |
| `tmux/tmux.conf`, `tmux/keys.txt` | `~/.config/tmux/` |
| `yazi/yazi.toml`, `keymap.toml`, `init.lua`, `plugins/open-vim.yazi` | `~/.config/yazi/` |
| `btop/btop.conf`, `btop/themes/plain.theme` | `~/.config/btop/` |
| `vim/vimrc` | `~/.vimrc` |
| `../nvim-config` (separate repo) | `~/.config/nvim` |
| `bin/*` | `~/.local/bin/` |

## Home tab panes

### procs

| Keys | Action |
|---|---|
| `j`/`k` or arrows | Move |
| `Tab` (or `←`/`→`, `1`/`2`) | Switch between apps and services |
| `x` | Force quit the selected app/process (asks `y`/`n`) |
| `t` | Quit it gently (SIGTERM) |
| `s` | Sort by cpu / memory / name |
| `/` | Filter by name (`Esc` clears) |
| `a` | Services: just yours ⇄ every user's (others' need sudo) |

sysinfo has no keys besides `q` (quit to the shell).

## ASCII art

The bottom of the home tab plays one of ten looping animations and moves on to another every two minutes:

| Scene | What happens |
|---|---|
| `bonsai` | A bonsai grows branch by branch from a pot, then drops its leaves. Each tree is new. |
| `aquarium` | Fish swim both ways past swaying seaweed while bubbles rise. |
| `rocket` | A rocket counts down, launches and arcs off the top of the sky. |
| `train` | A steam train crosses the hills, puffing smoke. |
| `sailboat` | A sailboat drifts across rolling night waves; gulls fly over. |
| `cat` | A cat walks across the grass after a butterfly, pouncing now and then. |
| `ufo` | A UFO hops between spots over the city and beams people up. |
| `bounce` | A drawing from `art/` bounces off the edges, changing color each hit. |
| `rain` | Clouds drift and rain falls on someone walking under an umbrella. |
| `snake` | A snake roams the pane hunting apples until it ties itself in a knot. |

Focus the art pane to control it: `n` / `p` next / previous scene, `space` pause, `k` hide the shortcuts box, `q` quit. Run `home-art <scene>` to play just one, or `home-art --list` to list them. Drop any `.txt` file into `art/` to add it to `bounce`.

## Cheat sheet

The same list opens with `Option+?` (in `tmux/keys.txt`). Option is the ⌥ key.

### Tabs

| Keys | Action |
|---|---|
| `Option+1..9` | Go to tab 1..9 |
| `Option+c` | New claude tab (pick a project) |
| `Option+d` | New developer tab (pick a project) |
| `Option+t` | New shell tab |
| `Option+r` | Rename tab |
| `Option+x` / `Option+Shift+w` | Close tab (not home) |

### Panes

| Keys | Action |
|---|---|
| `Option+arrows` | Move left/down/up/right |
| `Option+Shift+arrows` | Resize |
| `Option+z` | Zoom pane to the full tab (toggle) |
| `Option+v` / `Option+s` | Split side by side / top-bottom |
| `Option+w` | Close pane |
| `Option+u` | Scroll up through history (`j/k`, `Ctrl+u/d`, `v` select, `y` copy, `q` exit) |

The mouse still works as a fallback.

### yazi

| Keys | Action |
|---|---|
| `j`/`k` | Move down/up |
| `l` / `Enter` / click | Open folder / open file in nvim (in a developer tab, in the right pane) |
| `h` | Go up a folder |
| `a` | Create a file (end the name with `/` to make a folder) |
| `r` | Rename |
| `Space` | Select; `y` copy, `x` cut, `p` paste |
| `d` | Move to trash |
| `.` | Show/hide hidden files |
| `/` | Search in the folder |
| `q` | Quit (type `yazi` to reopen) |

### nvim

`Option+n` opens the full nvim cheat sheet (`keys.txt` in the nvim-config repo); `Space ?` shows the same list inside nvim. The basics:

| Keys | Action |
|---|---|
| `i` / `Esc` | Start typing / back to normal mode |
| `Ctrl+s` | Save |
| `Ctrl+p` | Find a file |
| `Space e` | File tree |
| `F5` | Run this file |
| `Space` (wait) | Shows everything that can follow |

Run `vimtutor` in the terminal for a 30-minute interactive lesson.

### Other

| Keys | Action |
|---|---|
| `Option+/` | tmux / Ghostty shortcuts |
| `Option+n` | nvim shortcuts |
| `Ctrl+b r` | Reload tmux config (a popup confirms it) |
| `Ctrl+b d` | Detach (session keeps running) |
| `Cmd+Shift+R` | Reload Ghostty config (a popup confirms it) |

tmux catches these Option shortcuts before the program in the pane sees them. For example, `Option+arrows` no longer jump by word in fish, and Claude Code's own Option shortcuts that overlap won't fire. Every other Option combination still passes through.

## Troubleshooting

- **Start the layout fresh:** run `tmux kill-server`, then open a new Ghostty window.
- **A pane's program exited:** the pane falls back to a shell. Type `claude`, `yazi`, `sysinfo`, `procs` or `home-art` to start it again. The developer tab's nvim pane can't fall back to a shell: quitting nvim shows the waiting screen again.
- **Ghostty opens a plain shell:** tmux isn't installed or isn't on PATH. Run `./install.sh tools`.
- **nvim says a language server failed to install:** run `:Mason` to see why. If npm complains about root-owned files in `~/.npm`, run `sudo chown -R $(id -u):$(id -g) ~/.npm` once.
