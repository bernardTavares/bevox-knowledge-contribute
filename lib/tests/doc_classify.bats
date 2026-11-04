#!/usr/bin/env bats

load helpers.bash

FIXTURES="$BATS_TEST_DIRNAME/fixtures"

@test "doc_classify: classifies valid PRD" {
    run "$(helper_path doc_classify.sh)" "$FIXTURES/valid-prd.md"
    [ "$status" -eq 0 ]
    [[ "$output" == prd* ]]
}

@test "doc_classify: classifies valid ADR by filename + headings" {
    tmp="$(mktemp -d)/ADR-999-test.md"
    cp "$FIXTURES/valid-adr.md" "$tmp"
    run "$(helper_path doc_classify.sh)" "$tmp"
    [ "$status" -eq 0 ]
    [[ "$output" == adr* ]]
    rm -rf "$(dirname "$tmp")"
}

@test "doc_classify: returns unknown for ambiguous doc with low confidence" {
    run "$(helper_path doc_classify.sh)" "$FIXTURES/ambiguous-doc.md"
    [ "$status" -eq 1 ]
    [[ "$output" == unknown* ]]
}

@test "doc_classify: emits confidence as second tab-separated field" {
    run "$(helper_path doc_classify.sh)" "$FIXTURES/valid-prd.md"
    [ "$status" -eq 0 ]
    conf="$(echo "$output" | awk -F'\t' '{print $2}')"
    [ -n "$conf" ]
    awk -v c="$conf" 'BEGIN { exit !(c+0 >= 0.7) }'
}

@test "doc_classify: rejects nonexistent file" {
    run "$(helper_path doc_classify.sh)" /tmp/nope-xyz.md
    [ "$status" -ne 0 ]
}
