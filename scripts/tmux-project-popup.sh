#!/bin/bash
#
# tmux-project-popup.sh - Open nvim with Zet project_scan in a tmux popup
#
# Usage: tmux-project-popup.sh
#
# Add to tmux.conf:
#   bind p run-shell "/path/to/tmux-project-popup.sh"
#

# Open tmux popup with nvim running Zet project_scan
# -E closes popup when nvim exits
# -w and -h set width/height as percentage
tmux popup -E -w 80% -h 80% nvim -c "Zet project_scan"
