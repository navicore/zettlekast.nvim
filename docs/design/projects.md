# Design: `#project` Tag — Active Project Tracker

## Intent

Daily notes and one-off notes handle individual tasks and reminders, but there's
no way to maintain a bird's-eye view of the 3–6 active projects and their
current next step. The `#project` tag fills that gap: a lightweight master
planner that lives inside existing notes (daily or otherwise) and is surfaced
via a dedicated Telescope picker showing only open items.

Reminders are time-bound and binary (done/not done). Projects are ongoing — the
value is seeing them collected in one picker so nothing falls through the cracks.

## Constraints

- Must not break existing `#reminder` autocmd or scanner logic.
- No new file format — projects live as lines inside normal `.md` notes.
- No special "projects file" — projects can be scattered across any note and the
  scanner aggregates them.
- Out of scope: due dates, priority ordering, sub-tasks, or any time-parsing.
  Keep it dead simple — a checkbox, a tag, and a description.

## Approach

Follow the `reminders/` subsystem pattern:

### 1. BufWritePre rewrite (`projects/autocmds.lua`)

On save, scan buffer lines for `#project`. Rewrite rules:

| Input | Output |
|---|---|
| `#project migrate off github` | `* [ ] #project: migrate off github` |
| `* [ ] #project: migrate off github` | _(no change — already formatted)_ |
| `* [x] #project: migrate off github` | _(no change — checked off)_ |

Same approach as `reminders/autocmds.lua:process_reminder_line` — detect whether
the prefix already exists, add it if not. The colon after `#project` is the
delimiter between tag and description.

### 2. Scanner (`projects/scanner.lua`)

Walk all vault files (respecting `scan_dirs`). For each line matching
`#project`, parse:
- **checked?** — `* [x]` vs `* [ ]`
- **description** — text after `#project:`
- **file + line number** — for navigation

The default picker shows only **unchecked** items (open projects). An "all"
variant can show everything.

### 3. Telescope picker (`projects/telescope.lua`)

Display open projects as: `description — filename:line`. Selecting an entry
opens the file at that line. This is the "master planner" view.

### 4. Wiring

- `lua/zet/projects/init.lua` — subsystem entry: `setup()`, `scan()`, `scan_all()`
- Add commands to `init.lua`: `project_scan`, `project_scan_all`
- Register BufWritePre autocmd alongside reminders in `setup()`
- Add `<leader>zp` default keymap for `project_scan`
- Add to panel command palette

### Module layout

```
lua/zet/projects/
  init.lua        — entry point, setup, public scan functions
  autocmds.lua    — BufWritePre line rewriting
  scanner.lua     — vault-wide file walker + parser
  telescope.lua   — picker for open/all projects
```

## Domain Events

| Event | Trigger | Effect |
|---|---|---|
| **BufWritePre** (existing) | User saves a `.md` file | `projects/autocmds.process_file()` rewrites raw `#project` lines to checkbox format |
| **Zet project_scan** (new command) | User invokes picker | Scanner walks vault, collects unchecked `#project` lines, opens Telescope |
| **Zet project_scan_all** (new command) | User invokes picker | Same but includes checked-off projects |

No new autocmds beyond hooking into the existing BufWritePre group. No
background processing, no timers — scanner runs on demand like reminders.

### 5. Tmux scripts (`scripts/`)

Follow the same pattern as `tmux-reminders.sh` and `tmux-reminder-popup.sh`.

**`scripts/tmux-projects.sh <path1> [path2] ...`** — Status-right counter.
Scans top-level `.md` files for unchecked `#project` lines (`grep -E '^\* \[ \] #project'`).
Outputs a tmux-styled badge with a click range:

- Open projects exist: `#[fg=...,bg=...,bold] 4 #[range=user|project] Proj #[norange]`
- No open projects: `#[fg=...,bg=...,nobold]#[range=user|project] Proj #[norange]`

Includes the same macOS sleep guard (`pmset -g powerstate`) as `tmux-reminders.sh`.

**`scripts/tmux-project-popup.sh`** — Opens `nvim -c "Zet project_scan"` in
an 80x80% tmux popup. Same one-liner pattern as `tmux-reminder-popup.sh`.

**tmux.conf additions** (user applies in `~/naviscripts/tmux.conf`):
```tmux
# Add to status-right, alongside the existing reminders call:
#(~/.local/share/nvim/lazy/zet.nvim/scripts/tmux-projects.sh $HOME/git/$(whoami)/zet)

# Keybinding:
bind p run-shell '$HOME/.local/share/nvim/lazy/zet.nvim/scripts/tmux-project-popup.sh'

# Click handler (add "project" range to the existing MouseDown1Status chain):
# if -F '#{==:#{mouse_status_range},project}' 'run-shell ...'
```

## Checkpoints

1. **Rewrite works**: type `#project migrate off github`, save, line becomes
   `* [ ] #project: migrate off github`. Already-formatted and checked lines
   are untouched.
2. **Scanner finds open projects**: scatter 3 `#project` lines (2 open, 1
   checked) across different notes. `project_scan` returns exactly the 2 open
   ones.
3. **Telescope picker navigates**: selecting an entry in the picker opens the
   correct file at the correct line.
4. **Panel includes new commands**: `project_scan` and `project_scan_all` appear
   in the Zet command palette.
5. **Reminders unaffected**: existing reminder tests still pass. A line with
   both `#reminder` and `#project` (unlikely but possible) is handled by
   whichever tag comes first — document this as undefined behavior.
6. **tmux-projects.sh counts correctly**: create 2 open + 1 checked `#project`
   lines, run the script, get `2`. With 0 open projects, output shows no count
   badge (just "Proj").
7. **tmux-project-popup.sh opens picker**: `bind p` opens a popup with the
   project_scan Telescope picker, closes cleanly on exit.
