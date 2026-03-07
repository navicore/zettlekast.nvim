# Roadmap

## Current State

The plugin is functional and actively used. Core features are stable:
- Note creation, linking, renaming with backlink updates
- Reminder parsing, scanning, snoozing, virtual text
- Contact import/export/dedup from VCF
- Telescope pickers for all operations
- Tmux integration scripts
- Custom `zet` filetype with syntax highlighting

## Known Gaps

- `archive_dirs` config defaults to empty — the README example lists year dirs but these aren't in defaults
- `default_keymaps` defaults to `true` in config but the README shows manual keybinding setup (no mention of built-in defaults)
- No automated CI — tests exist but no GitHub Actions workflow
