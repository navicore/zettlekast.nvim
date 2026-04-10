#!/bin/bash
#
# tmux-projects - Count open #project items across markdown files
# Outputs formatted string for tmux status-right
#
# Usage: tmux-projects.sh <path1> [path2] [path3] ...
#
# Example in tmux.conf:
#   set -g status-right '#(/path/to/tmux-projects.sh ~/notes ~/zet)'
#

# Skip when display is asleep (macOS) to allow system sleep
if [[ "$(uname)" == "Darwin" ]]; then
    _ps=$(pmset -g powerstate IOPMrootDomain 2>/dev/null | awk '/IOPMrootDomain/{print $3}')
    if [[ "$_ps" =~ ^[01]$ ]]; then
        exit 0
    fi
fi

if [[ $# -eq 0 ]]; then
    echo "Usage: tmux-projects.sh <path1> [path2] ..." >&2
    exit 1
fi

count=0

for dir in "$@"; do
    # Expand ~ to home directory
    dir="${dir/#\~/$HOME}"

    [[ -d "$dir" ]] || continue

    # Scan only top-level .md files (no recursion into archive dirs)
    for file in "$dir"/*.md; do
        [[ -f "$file" ]] || continue

        # Count unchecked #project lines
        c=$(grep -cE '^\* \[ \] #project:' "$file" 2>/dev/null)
        ((count += c))
    done
done

# Output for tmux with click support
# Show blue count badge only when there are open projects; nothing otherwise
if [[ "$count" -gt 0 ]]; then
    echo "#[fg=#131a24,bg=#719cd6,bold]#[range=user|project] ${count} #[norange]#[fg=#719cd6,bg=#131a24,nobold]"
fi
