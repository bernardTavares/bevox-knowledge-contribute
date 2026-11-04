# bevox-knowledge-contribute helpers

Small, single-purpose scripts used by the `bevox-knowledge-contribute` skill. Each one is standalone, signals its result through its exit code, and has no side effects beyond what its contract says.

## Helpers

| Helper | Purpose | Exit codes |
|---|---|---|
| `slot_resolve.sh` | Turn a slot into its expected folder paths | 0 ok · 1 unknown slot · 2 empty slot · 3 unknown folder · 4 missing slots.conf |
| `git_open_draft.sh` | Create an isolated worktree for a draft branch | 0 ok · 1 branch exists · 2 not a git repo |
| `git_commit_push.sh` | Stage, commit and push inside a worktree | 0 ok · 1 failure (rejected push, nothing to commit, …) |
| `frontmatter_validate.sh` | Validate YAML frontmatter per doc type | 0 ok · 1 YAML · 2 field · 3 value · 4 heading · 5 filename |
| `doc_classify.sh` | Guess a document's type with heuristics | 0 classified (≥ 0.7) · 1 ambiguous · other = error |
| `adr_next_number.sh` | Next global ADR number | 0 ok · 2 not a git repo |

## Conventions

- Readable errors go to stderr; structured data goes to stdout.
- No helper modifies `main` of the knowledge repo.
- No helper runs `git push --force`.
- `BEVOX_KNOWLEDGE_PATH` (default `$HOME/bevox-knowledge`) sets the knowledge repo root.
- `KNOWLEDGE_SLOTS_FILE` overrides the default `slots.conf`.
- `CLAUDE_CO_AUTHOR=0` drops the co-author trailer; `CLAUDE_CO_AUTHOR_LINE` changes it.

## Tests

The bats suite lives in `tests/`. From the repo root:

```bash
bats lib/tests e2e
```
