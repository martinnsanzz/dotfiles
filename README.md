# dotfiles

My keyboard-driven terminal setup for macOS. Opening Ghostty gives this workspace automatically, in a slightly see-through window with numbered tabs in the top bar. It starts with two tabs that can't be closed, home and calendar:

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

```
 2 calendar
┌──────────────────────────────┬──────────┐
│ ‹ November 2026 ›   d w m y  │ Today    │
│ Mon Tue Wed Thu Fri Sat Sun  │ 09:00–10 │
│  16  17 [18]  19  20  21  22 │ Standup  │
│                              │ 16:30–17 │
│ ─ Wed 18 November ─────────  ├──────────┤
│ █ 09:00–10:00 Standup        │ To do    │
│ █ 16:30–17:00 Codam          │ [ ] ! Pay│
│                              │ [ ]   Buy│
│                              │ ╭ keys ─╮│
└──────────────────────────────┴──────────┘
```

- **calendar** (`bin/calendar`): a day / week / month / year calendar. Move with the arrow keys, press `a` to add an event on the selected day (timed, all-day, or with just a start time), `e` to edit one, `x` to delete it. See [Calendar tab](#calendar-tab).
- **today** (`bin/calendar-today`): today's events with their times, all-day ones first. The one happening now is green, past ones are dimmed, and the bottom says how long until the next one. On a free day it says "Nothing today".
- **to do** (`bin/todo`): a to-do list under today's events. Press `a` to add one (with an optional due date and flag), `Space` to tick it off, `x` to delete it; its keys are always shown at the bottom of the pane. Done to-dos are cleared at midnight. See [To-do list](#to-do-list).

The calendar and today panes read and write the Mac's own Calendar, which syncs with iCloud, so the iPhone sees what you add here and the other way round.

Two more kinds of tab open on a project picker (`~` and the folders in `~/Projects`). Each tab is named after its project, like `claude:dotfiles` or `developer:libasm`:

```
 3 claude:dotfiles
┌──────────────────┬──────────┐
│                  │ lazygit  │
│   claude         │ (what    │
│                  │ changed) │
│                  ├──────────┤
│                  │ terminal │
└──────────────────┴──────────┘
```

- `Option+c` opens a **claude** tab (above) for any folder in `~/Projects`. Claude gets most of the width; lazygit shows every change it makes as it happens (diffs, staging, commits) and the terminal is for running things. Both start in the project. Outside a git repo the lazygit pane is a plain shell.
- `Option+d` opens a **developer** tab, for working on Codam projects: just nvim, full screen, opened on that project (`nvim .`). The nvim config brings its own file tree and terminal, so the tab needs nothing else.

```
 4 developer:libasm
┌──────────────────────────────┐
│                              │
│      nvim . (the project)    │
│                              │
└──────────────────────────────┘
```

`Option+e` opens a **file tree** (yazi) in a popup over any tab, in the folder of the pane you're in. Hovering a file previews it; Enter opens it in nvim in the popup, and quitting nvim (or `q` in the tree) closes the popup. To point Claude at a file, type `@` and its name in the claude pane.

## Install

```sh
git clone git@github.com:martinnsanzz/dotfiles.git ~/Projects/Claude/dotfiles
~/Projects/Claude/dotfiles/install.sh
```

`install.sh` also clones [nvim-config](https://github.com/martinnsanzz/nvim-config) next to this repo (`~/Projects/Claude/nvim-config`) if it isn't there yet. Then open Ghostty (`open -a Ghostty`). `./install.sh links` only re-creates the symlinks, compiles `calhelper` and `raise-windows` (when their source changed) and makes sure `raise-windows` is running; `./install.sh tools` only installs the tools. Any config that already exists is moved to `<name>.bak-<timestamp>` before it gets replaced.

## The tools

| Tool | What it is | Role here |
|---|---|---|
| [Ghostty](https://ghostty.org) | The terminal app. | It's the window. On launch it runs `bin/workspace`. |
| [tmux](https://github.com/tmux/tmux) | A terminal multiplexer. | Tabs (tmux "windows") and panes. The session keeps running after Ghostty closes. |
| [yazi](https://yazi-rs.github.io) | A terminal file manager. | The file tree popup (`Option+e`, `bin/tree-popup`). Hovering a file previews it; Enter or a click opens it in nvim. |
| [lazygit](https://github.com/jesseduffield/lazygit) | A git interface for the terminal. | The top-right pane of each claude tab, to review what Claude changed. Also used inside nvim. |
| [Neovim](https://neovim.io) | The text editor. | Set up like VS Code, in its own repo: [nvim-config](https://github.com/martinnsanzz/nvim-config). It fills the whole developer tab and opens files from the yazi tree. |
| [Claude Code](https://claude.com/claude-code) | AI coding assistant. | The left pane of each claude tab. |
| [btop](https://github.com/aristocratos/btop) | A live system monitor. | Not on the home tab any more; run `btop` for the full view (plain gray/blue theme). |
| [fzf](https://github.com/junegunn/fzf) | A fuzzy finder. | The project picker behind `Option+c` and `Option+d`. |
| `raise-windows` | A small Swift program running in the background. | Brings windows opened from a terminal (pygame, tkinter, `make run`, F5 in nvim) in front of Ghostty. See [Windows from the terminal](#windows-from-the-terminal). |
| EventKit (`calhelper`) | Apple's calendar framework. | `calendar/calhelper.swift`, compiled by `install.sh`, is the calendar tab's link to the Mac's Calendar and through it iCloud and the iPhone. |
| fish | The shell. | Every terminal pane. |
| Homebrew | The macOS package manager. | `install.sh` uses it to install everything. |

### How it fits together

1. `ghostty/config` sets `command = .../workspace`, so every Ghostty window runs that script instead of a plain shell. `macos-option-as-alt` makes the Option key work for tmux shortcuts, and `background-opacity` makes the window see-through. `maximize` and `window-save-state = never` make every window open maximized, including the one at login (otherwise macOS can "restore" zero windows and Ghostty shows nothing).
2. `bin/workspace` creates the tmux session `main` with the home and calendar tabs. If `main` already exists, it reattaches instead. That's why closing Ghostty loses nothing. It marks both with the tmux option `@locked`: `Option+x`/`Option+w` in `tmux.conf` refuse to close a locked tab (or its last pane), and a pane whose program exits there is restarted instead of closing.
3. `bin/dev claude [folder]` builds a claude/lazygit/terminal tab, and `bin/dev developer [folder]` opens a tab running `nvim .` in the folder. With `--pick` it first shows an fzf list of `~` and the folders in `~/Projects`.
4. `bin/home-art` plays looping ASCII animations across the bottom of the home tab, with the main shortcuts boxed in its top-right corner. It's Python (curses, standard library only), using the `python3` that comes with the Xcode command line tools.
5. `bin/sysinfo` and `bin/procs` fill the top-left of home. Both are Python curses like `home-art`. sysinfo reads CPU ticks straight from the kernel, procs reads `ps` and `lsappinfo` every 2 seconds. `btop/btop.conf` is kept for running btop by hand.
6. yazi's `open-nvim` plugin (`yazi/plugins/`, bound in `yazi/keymap.toml` and `yazi/init.lua`) opens files with `bin/yazi-nvim`, which swaps nvim into the tree's pane right away; quitting nvim brings the tree back. (yazi's built-in way of running an editor in its pane takes about 5 seconds to start.) The `Option+e` popup runs yazi through `bin/tree-popup`, which sets `YAZI_POPUP`: there Enter makes yazi hand back the chosen path and the popup opens it in nvim, and `q` (the `quit-popup` plugin) closes the popup through tmux. Both skip the same ~5 second wait yazi takes to give the terminal back.
7. `bin/calendar` and `bin/calendar-today` (Python curses) get events from `calhelper`, a small Swift program using EventKit that prints JSON (`calhelper list 2026-11-01 2026-11-30`, `add`, `update`, `delete`). They re-read every 30 seconds, and the today pane also reloads the moment the calendar changes something (it watches `~/.cache/dotfiles-calendar.stamp`).
8. `bin/todo` (Python curses) keeps the to-do list in `~/.local/share/todo.txt`. It checks the file every second, so edits made by hand show up right away, and on the first check after midnight it deletes the to-dos done before today.
9. `bin/flash` shows a short message in a centered tmux popup. `Ctrl+b r` uses it to confirm the tmux config reloaded. Ghostty's `Cmd+Shift+R` reloads Ghostty and then types a private key code that tmux binds (`User0`) to the same popup.
10. `raise-windows/raise-windows.swift` is compiled by `install.sh` to `~/.local/bin/raise-windows`, and a LaunchAgent (`~/Library/LaunchAgents/com.dotfiles.raise-windows.plist`, written by `install.sh`) starts it at login and restarts it if it stops.
11. `install.sh` symlinks each file in this repo to the place the app reads it from. Editing a file here changes the live config.

| Repo file | Linked to |
|---|---|
| `ghostty/config` | `~/.config/ghostty/config` |
| `tmux/tmux.conf`, `tmux/keys.txt` | `~/.config/tmux/` |
| `yazi/yazi.toml`, `keymap.toml`, `init.lua`, `plugins/open-nvim.yazi`, `plugins/quit-popup.yazi` | `~/.config/yazi/` |
| `btop/btop.conf`, `btop/themes/plain.theme` | `~/.config/btop/` |
| [nvim-config](https://github.com/martinnsanzz/nvim-config) (separate repo, cloned next to this one) | `~/.config/nvim` |
| `bin/*` | `~/.local/bin/` |
| `calendar/calhelper.swift` (compiled, not linked) | `~/.local/bin/calhelper` |
| `raise-windows/raise-windows.swift` (compiled, not linked) | `~/.local/bin/raise-windows`, started by `~/Library/LaunchAgents/com.dotfiles.raise-windows.plist` |

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

## Calendar tab

Tab 2 (`Option+2`) is a calendar for the Mac's Calendar app, with today's events on the right and a [to-do list](#to-do-list) under them. It can't be closed; quitting the calendar or today pane (`q`) just restarts it.

| Keys | Action |
|---|---|
| `←↓↑→` / `h j k l` | Move the selected day (a day left/right, a week up/down) |
| `n` / `p` (or `]` / `[`) | Next / previous month (week, day or year in those views) |
| `N` / `P` | Next / previous year |
| `m` `w` `d` `y` | Month, week, day, year view |
| `t` | Back to today |
| `g` | Go to a date: `2027-03-14`, `2027-03`, or just a day of this month |
| `a` / `Enter` | Add an event on the selected day |
| `Tab` then `j`/`k` | Choose one of the day's events (`Esc` back to the days) |
| `e` / `Enter` | Edit the chosen event |
| `x` / `Delete` | Delete it (asks `y`/`n`) |
| `r` | Re-read the calendar now |
| `?` | Every key |
| Mouse | Click a day to select it, double-click to add, scroll to page; click the view names at the top |

**Adding or editing** opens a small form: Title, All day, Date, then Starts/Ends (timed) or Until (all-day, for events over several days), and Where. `Tab`/`↓` next field, `↑` back, `Space` toggles all day, `Enter` saves, `Esc` cancels, `Ctrl+u` clears a field. Times can be typed as `9`, `930`, `9:30` or `14.30`; an end time before the start means the next day. New events go to your default calendar. Read-only calendars (Birthdays, subscribed holidays) are shown but can't be edited. For a repeating event only that one occurrence changes.

### Events without an end time

When you know when something starts but not when it ends, leave **Ends** empty:

1. Press `a` (or `e` on an existing event) and `Tab` down to **Ends**.
2. Press `Ctrl+u` to clear it, or type `N/A` (`na`, `-` and `?` work too). While you're on that field, the form's hint says "empty = no end time".
3. Press `Enter` to save.

The event then shows only its start time, `18:00` instead of `18:00–19:00`, in every view, in the Today pane and on the iPhone. In the Today pane it's green for its first minute, then dimmed as past. Editing it later opens with Ends empty again; type a time there to give it an end.

Apple's calendars always need an end time, so behind the scenes the event ends the moment it starts. That's what Calendar on the Mac and the iPhone show as just a start time too. New events still start with a one-hour end time filled in, so normal events take no extra keys.

### iPhone sync

The calendar doesn't talk to the iPhone itself: it reads and writes the Mac's Calendar database, and macOS syncs that with iCloud. So events made on the iPhone show up here (within the 30-second refresh once iCloud has synced, usually seconds), and events made here show up on the iPhone. For that:

1. **iCloud Calendar on for this Mac:** System Settings → your name → iCloud → Calendar (and on the iPhone: Settings → your name → iCloud → Calendar). The calendars should appear in the Mac's Calendar app.
2. **Default calendar is an iCloud one:** Calendar app → Settings → General → Default calendar, so events added here land in iCloud and not "On My Mac".
3. **Allow access once:** the first time, macOS asks whether Ghostty may access your calendars. If you said no, turn it on in System Settings → Privacy & Security → Calendars → Ghostty, then press `r`.

### To-do list

The bottom-right pane of the calendar tab (`Option+→` then `Option+↓`, or click it) is a to-do list. Its keys are always shown in the box at the bottom of the pane.

| Keys | Action |
|---|---|
| `j`/`k` or `↓`/`↑` | Move |
| `g` / `G` | First / last to-do |
| `a` | Add a to-do |
| `e` / `Enter` | Edit it |
| `Space` | Done / not done |
| `f` | Flag / unflag |
| `x` / `Delete` | Delete it (asks `y`/`n`) |
| `r` | Re-read the file |
| Mouse | Click a row to select it, click its `[ ]` to tick it, scroll to move |

**Adding or editing** opens a small form: Text, Due and Flag. `Tab`/`↓` next field, `↑` back, `Space` toggles the flag, `Enter` saves, `Esc` cancels, `Ctrl+u` clears a field. Due is optional and takes `today`, `tom`, a weekday (`fri`, the next one), a day of the month (`14`, this month or the next), `25/11`, or `2027-03-14`; the form shows the date it understood.

Flagged to-dos (`!`) come first, then by due date (overdue ones in red, today's in yellow), then the rest in the order you added them. Done ones (`✓`) sink to the bottom and are deleted at midnight.

The list is the plain text file `~/.local/share/todo.txt`, one to-do per line, so you can also edit it by hand; the pane picks up changes within a second:

```
[ ] Pay rent  due:2026-11-20  !
[ ] Buy milk
[x] Email Ana  done:2026-11-18
```

It stays on this Mac: unlike calendar events, to-dos don't sync to the iPhone.

## Windows from the terminal

On its own, macOS opens a window from a program you start in the terminal (a pygame game with `make run`, `python3 file.py`, F5 in nvim) *behind* Ghostty. Only the app you're using is allowed to hand focus to another app, and Ghostty never does, so the new window's request to come forward is refused.

`raise-windows` fixes that the way VS Code feels: the window opens in front, with focus, so you can play or type straight away. It runs in the background and:

1. gets a notice from macOS each time an app starts (a Python program becomes an app, "Python" in the Dock, when it opens its first window);
2. checks whether that app was started from a terminal, meaning one of its parent processes is tmux, nvim, make, a shell or Ghostty;
3. if so, waits for its window (up to 30 seconds) and brings it to the front with all its windows.

Apps you open from the Dock, Spotlight or Finder are started by macOS itself, not a terminal, so they're left alone. It works the same from a Ghostty tab, a tmux pane or nvim, because all three show up as parents. It needs no permissions and nothing extra installed: `install.sh` compiles it with the Xcode command line tools, like `calhelper`.

**Try it:** run this from a Ghostty tab, a tmux pane, or open it in nvim and press F5:

```sh
python3 ~/Projects/Claude/dotfiles/raise-windows/test-window.py
```

The window should open in front of Ghostty, say "has focus" in green, and show the keys you type without clicking it. `Esc` closes it.

To see what it's doing, stop the background copy and run one in the foreground; it prints each app it raises or ignores:

```sh
launchctl bootout gui/$(id -u)/com.dotfiles.raise-windows
raise-windows -v
```

`Ctrl+C` stops it; `./install.sh links` starts the background copy again.

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
| `Option+e` | File tree popup (yazi) in the current pane's folder |
| `Option+t` | New shell tab |
| `Option+r` | Rename tab |
| `Option+x` / `Option+Shift+w` | Close tab (not home or calendar) |

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
| `l` / `Enter` / click | Open folder / open file in nvim |
| (hover) | Preview the file in yazi's right column |
| `h` | Go up a folder |
| `a` | Create a file (end the name with `/` to make a folder) |
| `r` | Rename |
| `Space` | Select; `y` copy, `x` cut, `p` paste |
| `d` | Move to trash |
| `.` | Show/hide hidden files |
| `/` | Search in the folder |
| `q` | Quit (in the popup: close it) |

### nvim

`Option+n` opens the full nvim cheat sheet (`keys.txt` in the [nvim-config](https://github.com/martinnsanzz/nvim-config) repo); `Space ?` shows the same list inside nvim. The basics:

| Keys | Action |
|---|---|
| `i` / `Esc` | Start typing / back to normal mode |
| `Ctrl+s` | Save |
| `Ctrl+p` | Find a file |
| `Space e` | File tree |
| `F5` | Run this file |
| `Space` (wait) | Shows everything that can follow |

Run `nvim +Tutor` in the terminal for a 30-minute interactive lesson.

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
- **A window from the terminal still opens behind Ghostty:** check the background program runs with `launchctl print gui/$(id -u)/com.dotfiles.raise-windows | grep state` (it should say `running`); if not, run `./install.sh links`. Then run `raise-windows -v` as shown in [Windows from the terminal](#windows-from-the-terminal) to see whether it notices the app.
- **Calendar says no access or shows no events:** see [iPhone sync](#iphone-sync). Run `calhelper calendars` in a Ghostty pane to list the calendars it can see.
- **A pane's program exited:** the pane falls back to a shell. Type `claude`, `yazi`, `sysinfo`, `procs` or `home-art` to start it again. In a developer tab, quitting nvim leaves a shell in the project; type `nvim .` to reopen it.
- **Ghostty opens a plain shell:** tmux isn't installed or isn't on PATH. Run `./install.sh tools`.
- **nvim says a language server failed to install:** run `:Mason` to see why. If npm complains about root-owned files in `~/.npm`, run `sudo chown -R $(id -u):$(id -g) ~/.npm` once.
