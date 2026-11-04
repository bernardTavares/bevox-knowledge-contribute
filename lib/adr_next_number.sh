#!/usr/bin/env bash
# adr_next_number.sh — return next available ADR number across all slots
# Usage: adr_next_number.sh
# Stdout: 3-digit zero-padded number (e.g., "013")
# Exit 0: success / Exit 2: BEVOX_KNOWLEDGE_PATH not git repo

set -euo pipefail
export LC_ALL=C

bk_path="${BEVOX_KNOWLEDGE_PATH:-$HOME/bevox-knowledge}"

if ! git -C "$bk_path" rev-parse --git-dir >/dev/null 2>&1; then
    echo "error: '$bk_path' is not a git repository" >&2
    exit 2
fi

# Find max NNN across 30_adr/*/ADR-NNN-*.md
max="$(
    find "$bk_path/30_adr" -maxdepth 2 -name 'ADR-[0-9][0-9][0-9]-*.md' -type f 2>/dev/null \
        | sed -E 's|.*/ADR-([0-9]{3})-.*|\1|' \
        | sort -n | tail -1
)"

if [ -z "$max" ]; then
    next=1
else
    next=$((10#$max + 1))
fi

printf "%03d\n" "$next"
