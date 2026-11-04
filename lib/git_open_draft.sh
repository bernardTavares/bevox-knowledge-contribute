#!/usr/bin/env bash
# git_open_draft.sh — open isolated worktree for a draft branch
# Usage: git_open_draft.sh <branch_name>
#
# Known limitation: branch names that sanitize to the same dir name
# (e.g., 'draft/foo' and 'draft__foo' both → 'draft__foo') will collide
# at /tmp/bevox-knowledge-worktrees/. Stick to convention 'draft/<topic>'
# (CLAUDE.md §7) and this never bites.

set -euo pipefail

branch="${1:-}"
[ -z "$branch" ] && { echo "error: branch name required" >&2; exit 64; }

bk_path="${BEVOX_KNOWLEDGE_PATH:-$HOME/bevox-knowledge}"

if ! git -C "$bk_path" rev-parse --git-dir >/dev/null 2>&1; then
    echo "error: '$bk_path' is not a git repository" >&2
    exit 2
fi

# Refuse if branch already exists locally
if git -C "$bk_path" show-ref --verify --quiet "refs/heads/$branch"; then
    echo "error: branch '$branch' already exists; pick a new name or git branch -D" >&2
    exit 1
fi

# Sanitize branch → worktree dir name
sanitized="${branch//\//__}"
wt_root="/tmp/bevox-knowledge-worktrees"
wt_path="$wt_root/$sanitized"

mkdir -p "$wt_root"
# Defensive: stale worktree dir without git registration → remove
[ -d "$wt_path" ] && rm -rf "$wt_path"

# Base on origin/main if available, else local main
base="origin/main"
git -C "$bk_path" rev-parse --verify "$base" >/dev/null 2>&1 || base="main"

git -C "$bk_path" worktree add -q "$wt_path" -b "$branch" "$base"

echo "$wt_path"
