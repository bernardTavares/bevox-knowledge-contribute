#!/usr/bin/env bash
# install.sh — install bevox-knowledge-contribute skill into a project repo
# Usage: install.sh <project_repo_path> <project_name> <slot> [--force]

set -euo pipefail

project_dir="${1:-}"
project_name="${2:-}"
slot="${3:-}"
force=0
[ "${4:-}" = "--force" ] && force=1

if [ -z "$project_dir" ] || [ -z "$project_name" ] || [ -z "$slot" ]; then
    echo "Usage: install.sh <project_repo_path> <project_name> <slot> [--force]" >&2
    exit 64
fi

[ -d "$project_dir" ] || { echo "error: project dir '$project_dir' does not exist" >&2; exit 1; }

# Validate project_name shape (avoid YAML quoting issues with special chars)
if ! [[ "$project_name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
    echo "error: project_name must match [a-zA-Z0-9._-]+ (got: '$project_name')" >&2
    exit 64
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template="$script_dir/SKILL.md.template"
[ -f "$template" ] || { echo "error: SKILL.md.template missing at $template" >&2; exit 64; }

# Validate slot via slot_resolve.sh
if ! "$script_dir/lib/slot_resolve.sh" "$slot" >/dev/null 2>&1; then
    echo "error: '$slot' is non-canonical (not listed in slots.conf)" >&2
    exit 2
fi

target_dir="$project_dir/.claude/skills/bevox-knowledge-contribute"
target="$target_dir/SKILL.md"

if [ -f "$target" ] && [ "$force" -ne 1 ]; then
    echo "error: $target already exists; pass --force to overwrite" >&2
    exit 3
fi

mkdir -p "$target_dir"

# Substitute placeholders. Use bash parameter expansion to avoid sed quoting hell.
content="$(cat "$template")"
content="${content//\{PROJECT\}/$project_name}"
content="${content//\{SLOT\}/$slot}"
printf '%s\n' "$content" > "$target"

echo "installed: $target"
