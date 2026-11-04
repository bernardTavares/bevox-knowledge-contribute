#!/usr/bin/env bash
# frontmatter_validate.sh — validate doc frontmatter against schema
# Usage: frontmatter_validate.sh <doc_path> <doc_type>
#
# Exits:
#   0 valid
#   1 YAML malformed (or missing frontmatter entirely)
#   2 required field missing
#   3 field value out of allowed set (status/type/severity)
#   4 required heading missing
#   5 filename pattern violated
#  64 usage error / unknown doc_type / file not found

set -euo pipefail

doc="${1:-}"
doc_type="${2:-}"
if [ -z "$doc" ] || [ -z "$doc_type" ]; then
    echo "Usage: frontmatter_validate.sh <doc_path> <doc_type>" >&2
    exit 64
fi
[ -f "$doc" ] || { echo "error: doc '$doc' not found" >&2; exit 64; }

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
schema="$script_dir/schemas/$doc_type.yaml"
[ -f "$schema" ] || { echo "error: unknown doc_type '$doc_type'" >&2; exit 64; }

# Extract frontmatter (between first two --- lines)
fm="$(awk '
    /^---$/ { c++; if (c==1) next; if (c==2) exit }
    c==1 { print }
' "$doc")"

if [ -z "$fm" ]; then
    echo "error: no frontmatter found in $doc" >&2
    exit 1
fi

# Reject if a third "---" line appears immediately after the closing
# fence (i.e., a second pseudo-frontmatter block). Catches docs accidentally
# concatenated from multiple sources.
third_dash_line="$(awk '
    /^---$/ { c++; if (c==3) { print NR; exit } }
' "$doc")"
if [ -n "$third_dash_line" ]; then
    # Find line of the closing (second) ---
    second_dash_line="$(awk '/^---$/ { c++; if (c==2) { print NR; exit } }' "$doc")"
    # If third --- is within 2 lines of second, it's a back-to-back block
    if [ $((third_dash_line - second_dash_line)) -le 2 ]; then
        echo "error: doc has multiple '---' blocks at top (malformed frontmatter)" >&2
        exit 1
    fi
fi

# Validate YAML parses
if ! echo "$fm" | yq -P '.' >/dev/null 2>&1; then
    echo "error: malformed YAML frontmatter" >&2
    exit 1
fi

# Required fields
while IFS= read -r f; do
    [ -z "$f" ] && continue
    val="$(echo "$fm" | yq -r ".$f // \"__MISSING__\"")"
    if [ "$val" = "__MISSING__" ] || [ -z "$val" ] || [ "$val" = "null" ]; then
        echo "error: required field '$f' missing" >&2
        exit 2
    fi
done < <(yq -r '.required_fields[]' "$schema")

# Status values (if schema has them and frontmatter has status)
if yq -e '.status_values' "$schema" >/dev/null 2>&1; then
    status_val="$(echo "$fm" | yq -r '.status // ""')"
    if [ -n "$status_val" ] && [ "$status_val" != "null" ]; then
        ok=0
        while IFS= read -r s; do
            [ "$s" = "$status_val" ] && ok=1 && break
        done < <(yq -r '.status_values[]' "$schema")
        if [ "$ok" -ne 1 ]; then
            echo "error: status '$status_val' not in allowed set" >&2
            exit 3
        fi
    fi
fi

# type values (release-note, metrics)
if yq -e '.type_values' "$schema" >/dev/null 2>&1; then
    type_val="$(echo "$fm" | yq -r '.type // ""')"
    if [ -n "$type_val" ] && [ "$type_val" != "null" ]; then
        ok=0
        while IFS= read -r s; do
            [ "$s" = "$type_val" ] && ok=1 && break
        done < <(yq -r '.type_values[]' "$schema")
        if [ "$ok" -ne 1 ]; then
            echo "error: type '$type_val' not in allowed set" >&2
            exit 3
        fi
    fi
fi

# severity values (runbook)
if yq -e '.severity_values' "$schema" >/dev/null 2>&1; then
    sev_val="$(echo "$fm" | yq -r '.severity // ""')"
    if [ -n "$sev_val" ] && [ "$sev_val" != "null" ]; then
        ok=0
        while IFS= read -r s; do
            [ "$s" = "$sev_val" ] && ok=1 && break
        done < <(yq -r '.severity_values[]' "$schema")
        if [ "$ok" -ne 1 ]; then
            echo "error: severity '$sev_val' not in allowed set" >&2
            exit 3
        fi
    fi
fi

# Required headings
if yq -e '.required_headings' "$schema" >/dev/null 2>&1; then
    body="$(awk '/^---$/{c++; next} c>=2' "$doc")"
    while IFS= read -r pat; do
        [ -z "$pat" ] && continue
        if ! grep -qE "$pat" <<<"$body"; then
            echo "error: required heading missing (regex: $pat)" >&2
            exit 4
        fi
    done < <(yq -r '.required_headings[]' "$schema")
fi

# Filename pattern (ADR)
if yq -e '.filename_pattern' "$schema" >/dev/null 2>&1; then
    pat="$(yq -r '.filename_pattern' "$schema")"
    base="$(basename "$doc")"
    if ! grep -qE "$pat" <<<"$base"; then
        echo "error: filename '$base' violates pattern '$pat'" >&2
        exit 5
    fi
fi

exit 0
