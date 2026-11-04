#!/usr/bin/env bash
# init-knowledge.sh — create a knowledge repo layout and vendor this skill into it.
# Usage: scripts/init-knowledge.sh <knowledge_repo_path>
#
# Creates the canonical folders (with one subfolder per slot from slots.conf),
# copies the document templates into 99_templates/, and copies this skill into
# 99_templates/skill-bevox-knowledge-contribute/. It never commits or pushes.

set -euo pipefail

target="${1:-}"
[ -n "$target" ] || { echo "Usage: init-knowledge.sh <knowledge_repo_path>" >&2; exit 64; }

src="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$target"

mapfile -t slots < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$src/slots.conf" | grep -v '^$')
folders=(00_inbox 10_prd 20_architecture 30_adr 35_specs 40_roadmap 50_releases 60_customer-feedback 70_metrics)

for f in "${folders[@]}"; do
    for s in "${slots[@]}"; do
        mkdir -p "$target/$f/$s"
        [ -n "$(ls -A "$target/$f/$s")" ] || touch "$target/$f/$s/.gitkeep"
    done
done

mkdir -p "$target/99_templates/skill-bevox-knowledge-contribute"
cp "$src"/templates/*.md "$target/99_templates/"
for item in SKILL.md.template install.sh slots.conf lib; do
    cp -r "$src/$item" "$target/99_templates/skill-bevox-knowledge-contribute/"
done

echo "knowledge layout ready at: $target"
echo "next: git -C \"$target\" init && commit, then run"
echo "  $target/99_templates/skill-bevox-knowledge-contribute/install.sh <project_repo> <project_name> <slot>"
