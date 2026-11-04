#!/usr/bin/env bats

load helpers.bash

setup() { setup_test_bk; }
teardown() { teardown_test_bk; }

@test "slot_resolve: emits all 9 folder paths for canonical slot" {
    run "$(helper_path slot_resolve.sh)" backend
    [ "$status" -eq 0 ]
    [[ "$output" == *"00_inbox:$TEST_BK/00_inbox/backend"* ]]
    [[ "$output" == *"10_prd:$TEST_BK/10_prd/backend"* ]]
    [[ "$output" == *"30_adr:$TEST_BK/30_adr/backend"* ]]
    [[ "$output" == *"70_metrics:$TEST_BK/70_metrics/backend"* ]]
    # 9 lines (one per canonical folder)
    [ "$(echo "$output" | wc -l)" -eq 9 ]
}

@test "slot_resolve: --folder narrows to single path" {
    run "$(helper_path slot_resolve.sh)" web --folder 30_adr
    [ "$status" -eq 0 ]
    [ "$output" = "$TEST_BK/30_adr/web" ]
}

@test "slot_resolve: rejects non-canonical slot" {
    run "$(helper_path slot_resolve.sh)" not-a-real-slot
    [ "$status" -eq 1 ]
    [[ "$output" == *"non-canonical"* ]] || [[ "$stderr" == *"non-canonical"* ]]
}

@test "slot_resolve: rejects empty slot" {
    run "$(helper_path slot_resolve.sh)" ""
    [ "$status" -eq 2 ]
}

@test "slot_resolve: rejects unknown --folder name" {
    run "$(helper_path slot_resolve.sh)" backend --folder 99_not_a_folder
    [ "$status" -ne 0 ]
}

@test "slot_resolve: accepts every slot listed in slots.conf" {
    while read -r slot; do
        run "$(helper_path slot_resolve.sh)" "$slot"
        [ "$status" -eq 0 ] || { echo "failed for slot: $slot"; return 1; }
    done < <(sed -e 's/#.*//' -e 's/[[:space:]]//g' "$BATS_TEST_DIRNAME/../../slots.conf" | grep -v '^$')
}

@test "slot_resolve: KNOWLEDGE_SLOTS_FILE overrides slots.conf" {
    printf 'custom-slot\n' > "$TEST_BK/my-slots.conf"
    KNOWLEDGE_SLOTS_FILE="$TEST_BK/my-slots.conf" run "$(helper_path slot_resolve.sh)" custom-slot
    [ "$status" -eq 0 ]
    KNOWLEDGE_SLOTS_FILE="$TEST_BK/my-slots.conf" run "$(helper_path slot_resolve.sh)" backend
    [ "$status" -eq 1 ]
}
