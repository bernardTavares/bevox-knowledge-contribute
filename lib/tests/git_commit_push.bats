#!/usr/bin/env bats

load helpers.bash

setup() {
    setup_test_bk
    WT="$("$(dirname "$BATS_TEST_DIRNAME")/git_open_draft.sh" feat-test)"
}

teardown() {
    git -C "$TEST_BK" worktree remove --force "$WT" 2>/dev/null || true
    teardown_test_bk
}

@test "git_commit_push: stages, commits, pushes, returns hash + url" {
    echo "hello" > "$WT/00_inbox/note.md"
    run "$(helper_path git_commit_push.sh)" "$WT" "test: add note"
    [ "$status" -eq 0 ]
    # Output format: hash on line 1, url on line 2
    hash="$(echo "$output" | sed -n 1p)"
    [ ${#hash} -ge 7 ]
    git -C "$WT" log -1 --format=%H | grep -q "$hash"
    # Push landed on remote
    git -C "$REMOTE_BK" log feat-test --oneline | grep -q "test: add note"
}

@test "git_commit_push: injects Co-Authored-By by default" {
    echo "x" > "$WT/00_inbox/x.md"
    run "$(helper_path git_commit_push.sh)" "$WT" "test: x"
    [ "$status" -eq 0 ]
    git -C "$WT" log -1 --format=%B | grep -q "Co-Authored-By: Claude"
}

@test "git_commit_push: skips Co-Authored-By when CLAUDE_CO_AUTHOR=0" {
    echo "y" > "$WT/00_inbox/y.md"
    CLAUDE_CO_AUTHOR=0 run "$(helper_path git_commit_push.sh)" "$WT" "test: y"
    [ "$status" -eq 0 ]
    ! git -C "$WT" log -1 --format=%B | grep -q "Co-Authored-By"
}

@test "git_commit_push: fails when worktree is empty (no staged changes)" {
    run "$(helper_path git_commit_push.sh)" "$WT" "test: empty"
    [ "$status" -ne 0 ]
}

@test "git_commit_push: fails when worktree path doesn't exist" {
    run "$(helper_path git_commit_push.sh)" /tmp/nonexistent-wt-xyz "test: x"
    [ "$status" -ne 0 ]
}

@test "git_commit_push: never force-pushes (push rejection surfaces)" {
    # Simulate divergence: commit directly to bare remote on the same branch
    other="$(mktemp -d)"
    git clone -q -b main "$REMOTE_BK" "$other"
    git -C "$other" checkout -qb feat-test
    echo "remote-side" > "$other/00_inbox/r.md"
    git -C "$other" add . && git -C "$other" commit -q -m "remote: r"
    git -C "$other" push -q origin feat-test
    rm -rf "$other"

    echo "local-side" > "$WT/00_inbox/l.md"
    run "$(helper_path git_commit_push.sh)" "$WT" "test: l"
    [ "$status" -ne 0 ]
    [[ "$output" == *"reject"* ]] || [[ "$stderr" == *"reject"* ]] || \
        [[ "$output" == *"non-fast-forward"* ]] || [[ "$stderr" == *"non-fast-forward"* ]]
}
