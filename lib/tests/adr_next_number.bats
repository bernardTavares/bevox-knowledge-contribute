#!/usr/bin/env bats

load helpers.bash

setup() { setup_test_bk; }
teardown() { teardown_test_bk; }

@test "adr_next_number: returns 001 when no ADRs exist" {
    run "$(helper_path adr_next_number.sh)"
    [ "$status" -eq 0 ]
    [ "$output" = "001" ]
}

@test "adr_next_number: returns 002 when ADR-001 exists" {
    mkdir -p "$TEST_BK/30_adr/backend"
    touch "$TEST_BK/30_adr/backend/ADR-001-foo.md"
    run "$(helper_path adr_next_number.sh)"
    [ "$status" -eq 0 ]
    [ "$output" = "002" ]
}

@test "adr_next_number: scans across all slot subdirectories" {
    mkdir -p "$TEST_BK/30_adr/_shared" "$TEST_BK/30_adr/web"
    touch "$TEST_BK/30_adr/_shared/ADR-005-foo.md"
    touch "$TEST_BK/30_adr/web/ADR-009-bar.md"
    run "$(helper_path adr_next_number.sh)"
    [ "$status" -eq 0 ]
    [ "$output" = "010" ]
}

@test "adr_next_number: preserves gaps (no auto-fill)" {
    mkdir -p "$TEST_BK/30_adr/backend"
    touch "$TEST_BK/30_adr/backend/ADR-001-a.md"
    touch "$TEST_BK/30_adr/backend/ADR-003-b.md"
    # Gap at 002. Helper still returns 004 (max+1, not gap).
    run "$(helper_path adr_next_number.sh)"
    [ "$status" -eq 0 ]
    [ "$output" = "004" ]
}

@test "adr_next_number: zero-pads 3 digits even past 100" {
    mkdir -p "$TEST_BK/30_adr/backend"
    touch "$TEST_BK/30_adr/backend/ADR-099-foo.md"
    run "$(helper_path adr_next_number.sh)"
    [ "$status" -eq 0 ]
    [ "$output" = "100" ]
}

@test "adr_next_number: rejects when BEVOX_KNOWLEDGE_PATH is not git repo" {
    not_repo="$(mktemp -d)"
    BEVOX_KNOWLEDGE_PATH="$not_repo" run "$(helper_path adr_next_number.sh)"
    [ "$status" -eq 2 ]
    rm -rf "$not_repo"
}

@test "adr_next_number: ignores non-ADR files in 30_adr" {
    mkdir -p "$TEST_BK/30_adr/backend"
    touch "$TEST_BK/30_adr/backend/README.md"
    touch "$TEST_BK/30_adr/backend/ADR-002-foo.md"
    touch "$TEST_BK/30_adr/backend/draft-ADR.md"
    run "$(helper_path adr_next_number.sh)"
    [ "$status" -eq 0 ]
    [ "$output" = "003" ]
}
