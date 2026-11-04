#!/usr/bin/env bash
# doc_classify.sh — heuristic doc-type classification
# Usage: doc_classify.sh <doc_path>
# Stdout: <type>\t<confidence>
# Exit 0: confidence >= 0.7
# Exit 1: ambíguo (stdout = "unknown\t<best_score>" + candidates list)

set -euo pipefail

# Force C locale for awk numeric formatting (avoid PT-BR comma decimal).
export LC_ALL=C

doc="${1:-}"
if [ -z "$doc" ]; then
    echo "Usage: doc_classify.sh <doc_path>" >&2
    exit 64
fi
if [ ! -f "$doc" ]; then
    echo "error: doc '$doc' not found" >&2
    exit 64
fi

base="$(basename "$doc")"
fm="$(awk '/^---$/{c++; if(c==1)next; if(c==2)exit} c==1' "$doc" 2>/dev/null || true)"
body="$(awk '/^---$/{c++; next} c>=2' "$doc")"

# Initialize all type scores
declare -A score
for t in prd adr architecture spec runbook roadmap release-note customer-feedback metrics inbox; do
    score[$t]=0
done

bump() {
    local key="$1" delta="$2"
    score[$key]=$(awk -v s="${score[$key]}" -v d="$delta" 'BEGIN{print s+d}')
}

# Filename heuristics
if echo "$base" | grep -qE "^ADR-[0-9]{3}-"; then
    bump adr 0.5
fi
if echo "$base" | grep -qiE "^runbook-|^run-"; then
    bump runbook 0.4
fi
if echo "$base" | grep -qE "^[0-9]{4}-[0-9]{2}-[0-9]{2}-"; then
    bump spec 0.15
    bump inbox 0.1
fi
if echo "$base" | grep -qiE "release|^v[0-9]"; then
    bump release-note 0.3
fi
if echo "$base" | grep -qiE "roadmap"; then
    bump roadmap 0.3
fi
if echo "$base" | grep -qiE "metrics|metric-"; then
    bump metrics 0.3
fi
if echo "$base" | grep -qiE "feedback|customer-"; then
    bump customer-feedback 0.3
fi

# Frontmatter field heuristics
has_field() {
    [ -n "$fm" ] || return 1
    echo "$fm" | grep -qE "^${1}:[[:space:]]"
}

if [ -n "$fm" ]; then
    if has_field decisor && has_field tags; then
        bump adr 0.2
    fi
    if has_field severity && has_field maintainer; then
        bump runbook 0.4
    fi
    if has_field version && has_field type; then
        bump release-note 0.4
    fi
    if has_field source && has_field persona; then
        bump customer-feedback 0.4
    fi
    if has_field owner && has_field last_updated; then
        bump metrics 0.3
    fi
    if has_field decisor && has_field project && ! has_field severity; then
        bump prd 0.15
    fi
fi

# Body heading heuristics
if echo "$body" | grep -qE "^## Decisão" && echo "$body" | grep -qE "^## Consequências"; then
    bump adr 0.3
fi
if echo "$body" | grep -qE "^## Personas" && echo "$body" | grep -qE "^## Objetivos"; then
    bump prd 0.4
fi
if echo "$body" | grep -qE "^## Contexto" && echo "$body" | grep -qE "^## Problemas"; then
    bump prd 0.2
fi
if echo "$body" | grep -qE "^## Pre-checks" && echo "$body" | grep -qE "^## Rollback"; then
    bump runbook 0.3
fi
if echo "$body" | grep -qE "^## Wave em curso"; then
    bump roadmap 0.4
fi
if echo "$body" | grep -qE "^## Highlights"; then
    bump release-note 0.3
fi
if echo "$body" | grep -qE "^## Feedback raw"; then
    bump customer-feedback 0.3
fi
if echo "$body" | grep -qE "^## Definição" && echo "$body" | grep -qE "^## Cálculo"; then
    bump metrics 0.3
fi

# Pick winner
best_type="unknown"
best_score=0
for t in "${!score[@]}"; do
    if awk -v s="${score[$t]}" -v b="$best_score" 'BEGIN{exit !(s>b)}'; then
        best_type="$t"
        best_score="${score[$t]}"
    fi
done

threshold=0.7
if awk -v s="$best_score" -v t="$threshold" 'BEGIN{exit !(s>=t)}'; then
    printf "%s\t%.2f\n" "$best_type" "$best_score"
    exit 0
else
    printf "unknown\t%.2f\n" "$best_score"
    # Print top-3 candidates
    {
        for t in "${!score[@]}"; do
            if awk -v s="${score[$t]}" 'BEGIN{exit !(s>0)}'; then
                printf "  candidate: %s\t%.2f\n" "$t" "${score[$t]}"
            fi
        done
    } | sort -k3 -r -t$'\t' | head -3
    exit 1
fi
