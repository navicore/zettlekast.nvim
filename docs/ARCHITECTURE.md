# Architecture

## Overview

zet.nvim is a Neovim plugin for Zettelkasten note-taking with reminders and
contact management. It uses Telescope for all pickers and operates on plain
markdown files in a configured directory.

## Entry Points

- `plugin/zet.lua` — Registers the `:Zet` user command (with tab completion) and sets the `zet` filetype for `.md` files inside the vault.
- `lua/zet/init.lua` — Public API module. `setup()` initializes config, calendar, and reminders. All commands delegate to submodules via thin wrapper functions.

## Module Map

```
lua/zet/
  init.lua          — Public API, setup, command list
  config.lua        — Defaults, user config merge, path expansion
  notes.lua         — new_note, new_templated_note, rename_note, goto_today
  links.lua         — follow_link (resolve/create), insert_link
  pickers.lua       — Telescope pickers: find_notes, find_daily_notes, search_notes, panel
  tags.lua          — #tag scanning and Telescope picker
  templates.lua     — Template file reading and {{variable}} substitution
  dates.lua         — Date formatting helpers (daily/weekly filenames, human dates)
  utils.lua         — Shared utilities (path helpers, file I/O)
  calendar.lua      — calendar-vim integration (setup globals, open calendar, daily action)
  history.lua       — Git line history via Telescope

  reminders/
    init.lua         — Reminder subsystem entry point (scan, edit, setup)
    scanner.lua      — Walks vault files, parses #reminder lines, filters by due/upcoming
    time_parser.lua  — Natural language time -> ISO 8601 conversion
    virtual_text.lua — Countdown extmarks on reminder lines
    snooze.lua       — Snooze/edit reminder timestamps
    autocmds.lua     — BufWritePre: auto-convert natural language times on save
    telescope.lua    — Telescope picker for reminder results

  projects/
    init.lua         — Project subsystem entry point (scan, scan_all, setup)
    autocmds.lua     — BufWritePre: auto-format #project lines to checkbox markdown
    scanner.lua      — Walks vault files, parses #project lines, filters open/all
    telescope.lua    — Telescope picker for project results

  contacts/
    init.lua         — Contact subsystem entry point (import, find, dedup, export)
    vcf_parser.lua   — VCF 3.0 parser (handles folded lines, quoted-printable, etc.)
    vcf_writer.lua   — Export contacts back to VCF format
    markdown.lua     — Contact -> markdown file with YAML frontmatter
    telescope.lua    — Telescope picker showing name/email/org
    dedup.lua        — Duplicate detection (normalized names, shared emails) and merge
```

## Vim Integration Files

- `autoload/zet.vim` — Legacy VimL autoload (used by calendar-vim callback)
- `syntax/zet.vim` — Syntax highlighting for `[[links]]`, `==highlights==`, `#tags`
- `ftplugin/zet.vim` — Filetype settings for `zet` buffers

## Scripts

- `scripts/tmux-reminders.sh` — Counts due reminders for tmux status bar
- `scripts/tmux-reminder-popup.sh` — Opens reminder scan in a tmux popup
- `scripts/tmux-zett-popup.sh` — Opens zet note finder in a tmux popup
- `scripts/tmux-projects.sh` — Counts open projects for tmux status bar
- `scripts/tmux-project-popup.sh` — Opens project scan in a tmux popup
- `scripts/minimal_init.vim` — Minimal Neovim config for running tests

## Data Flow

1. **Setup**: User calls `require("zet").setup(opts)` -> config merges defaults -> calendar globals set -> reminder autocmds registered.
2. **Notes**: All notes are plain `.md` files in `config.home` (and `archive_dirs`). Filenames are generated from UUID + title patterns. Templates use `{{variable}}` substitution.
3. **Links**: `[[Name]]` links resolve to files by scanning vault filenames. Following a link opens or creates the target file.
4. **Reminders**: On save, `time_parser` converts natural language (`in 2 hours`) to ISO 8601 in-place. Scanner walks all files for `#reminder` lines and filters by due date. Virtual text shows countdowns.
5. **Projects**: On save, raw `#project <desc>` lines are rewritten to `* [ ] #project: <desc>`. Scanner walks all files for `#project` lines; default picker shows only unchecked (open) items.
6. **Contacts**: VCF import parses entries -> writes one `.md` per contact with YAML frontmatter. Dedup clusters by normalized name or shared email. Export reverses the process.

## Tests

Tests live in `tests/` and use plenary.nvim's busted-style test runner
(`scripts/minimal_init.vim` for isolated Neovim). Coverage includes: time
parser, dates, templates, links, notes, VCF parser, contacts markdown, and dedup
logic.

## Dependencies

- **Required**: telescope.nvim, plenary.nvim
- **Optional**: calendar-vim, render-markdown.nvim
