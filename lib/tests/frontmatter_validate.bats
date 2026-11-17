#!/usr/bin/env bats

load helpers.bash

FIXTURES="$BATS_TEST_DIRNAME/fixtures"

@test "frontmatter_validate: passes valid PRD" {
    run "$(helper_path frontmatter_validate.sh)" "$FIXTURES/valid-prd.md" prd
    [ "$status" -eq 0 ]
}

@test "frontmatter_validate: passes valid ADR" {
    # Rename temp so filename pattern matches
    tmp="$(mktemp -d)/ADR-999-sample.md"
    cp "$FIXTURES/valid-adr.md" "$tmp"
    run "$(helper_path frontmatter_validate.sh)" "$tmp" adr
    [ "$status" -eq 0 ]
    rm -rf "$(dirname "$tmp")"
}

@test "frontmatter_validate: accepts a document made from the ADR template" {
    local template="$BATS_TEST_DIRNAME/../../templates/adr.md"
    local adr="$BATS_TEST_TMPDIR/ADR-001-from-template.md"
    {
        printf '%s\n' '---' 'status: proposed' 'date: 2026-05-01' 'decisor: Example' 'tags: [template]' '---'
        cat "$template"
    } > "$adr"

    run "$(helper_path frontmatter_validate.sh)" "$adr" adr
    [ "$status" -eq 0 ]
}

@test "frontmatter_validate: ADR template lists the schema statuses" {
    local schema="$BATS_TEST_DIRNAME/../schemas/adr.yaml"
    local template="$BATS_TEST_DIRNAME/../../templates/adr.md"
    local statuses
    statuses="$(yq -r '.status_values | join(" | ")' "$schema")"

    run grep -Fx -- "- **Status:** [$statuses]" "$template"
    [ "$status" -eq 0 ]
}

@test "frontmatter_validate: rejects malformed YAML (exit 1)" {
    run "$(helper_path frontmatter_validate.sh)" "$FIXTURES/invalid-yaml.md" prd
    [ "$status" -eq 1 ]
}

@test "frontmatter_validate: rejects missing required field (exit 2)" {
    run "$(helper_path frontmatter_validate.sh)" "$FIXTURES/missing-field-prd.md" prd
    [ "$status" -eq 2 ]
    [[ "$output" == *"decisor"* ]] || [[ "$stderr" == *"decisor"* ]]
}

@test "frontmatter_validate: rejects out-of-set status (exit 3)" {
    tmp="$(mktemp -d)/ADR-998-wrong.md"
    cp "$FIXTURES/wrong-status-adr.md" "$tmp"
    run "$(helper_path frontmatter_validate.sh)" "$tmp" adr
    [ "$status" -eq 3 ]
    rm -rf "$(dirname "$tmp")"
}

@test "frontmatter_validate: rejects ADR with non-canonical filename (exit 5)" {
    tmp="$(mktemp -d)/wrong-name.md"
    cp "$FIXTURES/valid-adr.md" "$tmp"
    run "$(helper_path frontmatter_validate.sh)" "$tmp" adr
    [ "$status" -eq 5 ]
    rm -rf "$(dirname "$tmp")"
}

@test "frontmatter_validate: rejects unknown doc_type" {
    run "$(helper_path frontmatter_validate.sh)" "$FIXTURES/valid-prd.md" not-a-type
    [ "$status" -ne 0 ]
}

@test "frontmatter_validate: rejects when doc has no frontmatter at all" {
    tmp="$(mktemp).md"
    echo "# Just a heading" > "$tmp"
    run "$(helper_path frontmatter_validate.sh)" "$tmp" prd
    [ "$status" -eq 1 ]
    rm -f "$tmp"
}

@test "frontmatter_validate: rejects doc with multiple ---  blocks at top (exit 1)" {
    run "$(helper_path frontmatter_validate.sh)" "$FIXTURES/multi-block-fm.md" prd
    [ "$status" -eq 1 ]
}
