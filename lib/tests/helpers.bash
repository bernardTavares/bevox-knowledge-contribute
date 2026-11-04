# Shared setup/teardown for bevox-knowledge-contribute helper tests.
# Each test gets an isolated fake BEVOX_KNOWLEDGE_PATH initialized as
# a real git repo (so worktree-based helpers can operate against it).

setup_test_bk() {
    TEST_BK="$(mktemp -d -t bk-test.XXXXXX)"
    export BEVOX_KNOWLEDGE_PATH="$TEST_BK"
    git -C "$TEST_BK" init -q -b main
    git -C "$TEST_BK" config user.email "test@bevox.local"
    git -C "$TEST_BK" config user.name "Test"
    # Mirror canonical folder structure (9 folders × 11 slots is overkill
    # for tests; create only what each test needs).
    for f in 00_inbox 10_prd 20_architecture 30_adr 35_specs \
             40_roadmap 50_releases 60_customer-feedback 70_metrics \
             99_templates; do
        mkdir -p "$TEST_BK/$f"
        touch "$TEST_BK/$f/.gitkeep"
    done
    # Initial commit so HEAD exists and worktree commands have a base.
    touch "$TEST_BK/.gitkeep"
    git -C "$TEST_BK" add . >/dev/null
    git -C "$TEST_BK" commit -q -m "init test bk"
    # Fake remote so push commands can be tested without external network.
    REMOTE_BK="$(mktemp -d -t bk-remote.XXXXXX)"
    git init -q --bare "$REMOTE_BK"
    git -C "$TEST_BK" remote add origin "$REMOTE_BK"
    git -C "$TEST_BK" push -q -u origin main
    export TEST_BK REMOTE_BK
}

teardown_test_bk() {
    [ -n "${TEST_BK:-}" ] && rm -rf "$TEST_BK"
    [ -n "${REMOTE_BK:-}" ] && rm -rf "$REMOTE_BK"
    # Cleanup any worktrees created in /tmp/bevox-knowledge-worktrees
    rm -rf /tmp/bevox-knowledge-worktrees/test-* 2>/dev/null || true
}

# Path to the helper script under test, resolved from BATS_TEST_DIRNAME.
helper_path() {
    echo "$BATS_TEST_DIRNAME/../$1"
}
