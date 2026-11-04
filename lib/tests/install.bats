#!/usr/bin/env bats

load helpers.bash

setup() {
    setup_test_bk
    # Copy templates + lib into TEST_BK so install.sh can find them
    mkdir -p "$TEST_BK/99_templates/skill-bevox-knowledge-contribute/lib"
    cp -r "$(dirname "$BATS_TEST_DIRNAME")"/* \
        "$TEST_BK/99_templates/skill-bevox-knowledge-contribute/lib/"
    cp "$(dirname "$BATS_TEST_DIRNAME")/../SKILL.md.template" \
        "$TEST_BK/99_templates/skill-bevox-knowledge-contribute/" 2>/dev/null || true
    cp "$(dirname "$BATS_TEST_DIRNAME")/../install.sh" \
        "$TEST_BK/99_templates/skill-bevox-knowledge-contribute/" 2>/dev/null || true
    cp "$(dirname "$BATS_TEST_DIRNAME")/../slots.conf" \
        "$TEST_BK/99_templates/skill-bevox-knowledge-contribute/"
    PROJECT_DIR="$(mktemp -d)"
}

teardown() {
    rm -rf "$PROJECT_DIR"
    teardown_test_bk
}

install_path() {
    echo "$TEST_BK/99_templates/skill-bevox-knowledge-contribute/install.sh"
}

@test "install: creates .claude/skills/bevox-knowledge-contribute/SKILL.md" {
    run "$(install_path)" "$PROJECT_DIR" sample-project backend
    [ "$status" -eq 0 ]
    [ -f "$PROJECT_DIR/.claude/skills/bevox-knowledge-contribute/SKILL.md" ]
}

@test "install: substitutes {PROJECT} and {SLOT} placeholders" {
    run "$(install_path)" "$PROJECT_DIR" my-project backend
    [ "$status" -eq 0 ]
    skill="$PROJECT_DIR/.claude/skills/bevox-knowledge-contribute/SKILL.md"
    grep -q "project: my-project" "$skill"
    grep -q "slot: backend" "$skill"
    ! grep -q "{PROJECT}" "$skill"
    ! grep -q "{SLOT}" "$skill"
}

@test "install: rejects nonexistent project_repo_path" {
    run "$(install_path)" /tmp/nope-xyz proj backend
    [ "$status" -eq 1 ]
}

@test "install: rejects non-canonical slot" {
    run "$(install_path)" "$PROJECT_DIR" proj not-a-slot
    [ "$status" -eq 2 ]
}

@test "install: refuses overwrite without --force" {
    "$(install_path)" "$PROJECT_DIR" proj backend
    run "$(install_path)" "$PROJECT_DIR" proj backend
    [ "$status" -eq 3 ]
}

@test "install: --force overwrites existing SKILL.md" {
    "$(install_path)" "$PROJECT_DIR" proj backend
    run "$(install_path)" "$PROJECT_DIR" proj backend --force
    [ "$status" -eq 0 ]
}

@test "install: rejects project_name with colon" {
    run "$(install_path)" "$PROJECT_DIR" "bad:name" backend
    [ "$status" -eq 64 ]
}

@test "install: accepts project_name with allowed chars (alnum, dot, underscore, hyphen)" {
    run "$(install_path)" "$PROJECT_DIR" "my-api.v2_alpha" backend
    [ "$status" -eq 0 ]
}
