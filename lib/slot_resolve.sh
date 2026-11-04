#!/usr/bin/env bash
# slot_resolve.sh — resolve canonical slot to expected folder paths
# Usage: slot_resolve.sh <slot> [--folder <name>]

set -euo pipefail

# Slots (one per project) come from slots.conf at the skill root, or from the
# file named by KNOWLEDGE_SLOTS_FILE. One slot per line; "#" starts a comment.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
slots_file="${KNOWLEDGE_SLOTS_FILE:-$script_dir/../slots.conf}"
if [ ! -f "$slots_file" ]; then
    echo "error: slots file not found: $slots_file" >&2
    exit 4
fi
mapfile -t CANONICAL_SLOTS < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$slots_file" | grep -v '^$')

CANONICAL_FOLDERS=(
    00_inbox 10_prd 20_architecture 30_adr 35_specs
    40_roadmap 50_releases 60_customer-feedback 70_metrics
)

usage() {
    echo "Usage: slot_resolve.sh <slot> [--folder <name>]" >&2
    exit 64
}

slot="${1:-}"
[ -z "$slot" ] && { echo "error: slot is required" >&2; exit 2; }

shift || true
folder_filter=""
while [ $# -gt 0 ]; do
    case "$1" in
        --folder)
            folder_filter="${2:-}"
            [ -z "$folder_filter" ] && usage
            shift 2
            ;;
        *) usage ;;
    esac
done

# Validate slot
slot_ok=0
for s in "${CANONICAL_SLOTS[@]}"; do
    [ "$s" = "$slot" ] && slot_ok=1 && break
done
if [ "$slot_ok" -ne 1 ]; then
    echo "error: '$slot' is non-canonical (not listed in slots.conf)" >&2
    exit 1
fi

bk_path="${BEVOX_KNOWLEDGE_PATH:-$HOME/bevox-knowledge}"

if [ -n "$folder_filter" ]; then
    folder_ok=0
    for f in "${CANONICAL_FOLDERS[@]}"; do
        [ "$f" = "$folder_filter" ] && folder_ok=1 && break
    done
    if [ "$folder_ok" -ne 1 ]; then
        echo "error: '$folder_filter' is not a canonical folder (see README: folder layout)" >&2
        exit 3
    fi
    echo "$bk_path/$folder_filter/$slot"
    exit 0
fi

for f in "${CANONICAL_FOLDERS[@]}"; do
    echo "$f:$bk_path/$f/$slot"
done
