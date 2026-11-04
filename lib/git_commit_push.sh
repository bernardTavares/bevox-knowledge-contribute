#!/usr/bin/env bash
# git_commit_push.sh — stage, commit, push from worktree
# Usage: git_commit_push.sh <worktree_path> <commit_message>

set -euo pipefail

wt="${1:-}"
msg="${2:-}"
if [ -z "$wt" ] || [ -z "$msg" ]; then
    echo "Usage: git_commit_push.sh <worktree_path> <commit_message>" >&2
    exit 64
fi

[ -d "$wt" ] || { echo "error: worktree '$wt' does not exist" >&2; exit 1; }
git -C "$wt" rev-parse --git-dir >/dev/null 2>&1 || {
    echo "error: '$wt' is not a git worktree" >&2; exit 1;
}

# Stage everything
git -C "$wt" add -A

# Bail if nothing staged
if git -C "$wt" diff --cached --quiet; then
    echo "error: nothing to commit (worktree clean after add)" >&2
    exit 1
fi

# Build commit message (with optional Co-Authored-By)
co_author="${CLAUDE_CO_AUTHOR:-1}"
if [ "$co_author" = "1" ]; then
    full_msg="$msg

${CLAUDE_CO_AUTHOR_LINE:-Co-Authored-By: Claude <noreply@anthropic.com>}"
else
    full_msg="$msg"
fi

git -C "$wt" commit -q -m "$full_msg"

# Push (no force, ever). Capture chatter; only emit it to stderr on
# failure. Stdout stays reserved for the hash + URL contract.
branch="$(git -C "$wt" rev-parse --abbrev-ref HEAD)"
push_log="$(mktemp)"
if ! git -C "$wt" push -u origin "$branch" >"$push_log" 2>&1; then
    cat "$push_log" >&2
    rm -f "$push_log"
    echo "error: push rejected — pull/rebase manually and retry" >&2
    exit 1
fi
rm -f "$push_log"

hash="$(git -C "$wt" rev-parse HEAD)"
remote_url="$(git -C "$wt" remote get-url origin)"
# Convert SSH to HTTPS for printable URL where possible
case "$remote_url" in
    git@*:*) https_url="${remote_url/:/\/}"; https_url="${https_url/git@/https://}";;
    *) https_url="$remote_url" ;;
esac
echo "$hash"
echo "$https_url/tree/$branch"
