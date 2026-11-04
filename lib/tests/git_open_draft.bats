#!/usr/bin/env bats

load helpers.bash

setup() { setup_test_bk; }
teardown() { teardown_test_bk; }

@test "git_open_draft: creates worktree on origin/main, returns path" {
    run "$(helper_path git_open_draft.sh)" test-feature
    [ "$status" -eq 0 ]
    wt="$output"
    [ -d "$wt" ]
    [ -d "$wt/.git" ] || [ -f "$wt/.git" ]
    # branch should exist
    git -C "$wt" rev-parse --abbrev-ref HEAD | grep -q "test-feature"
}

@test "git_open_draft: sanitizes slash in branch name for worktree dir" {
    run "$(helper_path git_open_draft.sh)" draft/test-slash
    [ "$status" -eq 0 ]
    [[ "$output" == */bevox-knowledge-worktrees/* ]]
    [[ "$output" != */draft/test-slash ]]
}

@test "git_open_draft: rejects existing branch" {
    git -C "$TEST_BK" branch existing-br
    run "$(helper_path git_open_draft.sh)" existing-br
    [ "$status" -eq 1 ]
    [[ "$output" == *"already exists"* ]] || [[ "$stderr" == *"already exists"* ]]
}

@test "git_open_draft: rejects when BEVOX_KNOWLEDGE_PATH is not git repo" {
    not_repo="$(mktemp -d)"
    BEVOX_KNOWLEDGE_PATH="$not_repo" run "$(helper_path git_open_draft.sh)" any-br
    [ "$status" -eq 2 ]
    rm -rf "$not_repo"
}

@test "git_open_draft: idempotent worktree dir cleanup if same branch reused after removal" {
    run "$(helper_path git_open_draft.sh)" reuse-br
    [ "$status" -eq 0 ]
    wt="$output"
    git -C "$TEST_BK" worktree remove --force "$wt"
    git -C "$TEST_BK" branch -D reuse-br
    run "$(helper_path git_open_draft.sh)" reuse-br
    [ "$status" -eq 0 ]
}
