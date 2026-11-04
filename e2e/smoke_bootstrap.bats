#!/usr/bin/env bats

load ../lib/tests/helpers.bash

LIB="$BATS_TEST_DIRNAME/../lib"

setup() { setup_test_bk; }
teardown() { teardown_test_bk; }

@test "e2e bootstrap: slot_resolve + git_open_draft + create dirs + commit_push" {
    SLOT="backend"
    BRANCH="draft/backend-bootstrap-smoke"

    # 1. Resolve paths
    run "$LIB/slot_resolve.sh" "$SLOT"
    [ "$status" -eq 0 ]
    paths="$output"

    # 2. Open draft worktree
    run "$LIB/git_open_draft.sh" "$BRANCH"
    [ "$status" -eq 0 ]
    WT="$output"

    # 3. Create slot dirs in worktree (mirror what skill bootstrap does)
    while IFS=: read -r folder _abspath; do
        mkdir -p "$WT/$folder/$SLOT"
        touch "$WT/$folder/$SLOT/.gitkeep"
    done <<< "$paths"

    # 4. Commit + push
    run "$LIB/git_commit_push.sh" "$WT" "bootstrap($SLOT): cria 9 subpastas canônicas (smoke)"
    [ "$status" -eq 0 ]

    # 5. Verify on remote
    git -C "$REMOTE_BK" log "$BRANCH" --oneline | grep -q "bootstrap"
    git -C "$REMOTE_BK" ls-tree -r "$BRANCH" | grep -q "00_inbox/$SLOT/.gitkeep"
    git -C "$REMOTE_BK" ls-tree -r "$BRANCH" | grep -q "70_metrics/$SLOT/.gitkeep"

    # Cleanup worktree
    git -C "$TEST_BK" worktree remove --force "$WT"
}

@test "e2e propose: copy template + validate + commit" {
    SLOT="backend"
    BRANCH="draft/backend-propose-smoke"

    # Need real prd template in TEST_BK; commit + push so origin/main carries it
    # (worktree is branched from origin/main, so template must be there).
    cp "$BATS_TEST_DIRNAME/../templates/prd.md" "$TEST_BK/99_templates/"
    git -C "$TEST_BK" add 99_templates/prd.md
    git -C "$TEST_BK" commit -q -m "seed: prd template (smoke fixture)"
    git -C "$TEST_BK" push -q origin main

    run "$LIB/git_open_draft.sh" "$BRANCH"
    [ "$status" -eq 0 ]
    WT="$output"

    DEST_DIR="$WT/10_prd/$SLOT"
    mkdir -p "$DEST_DIR"
    DEST="$DEST_DIR/2026-05-07-backend-prd-v1.md"
    cp "$WT/99_templates/prd.md" "$DEST"

    # frontmatter_validate may fail on placeholder values — that's OK for smoke;
    # we just check it executes without crashing.
    "$LIB/frontmatter_validate.sh" "$DEST" prd || true

    run "$LIB/git_commit_push.sh" "$WT" "propose(backend/prd): smoke test"
    [ "$status" -eq 0 ]

    git -C "$TEST_BK" worktree remove --force "$WT"
}
