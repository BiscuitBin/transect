# 05: Hooks and document linting

**What to build:** A commit that breaks formatting, contains a typo, a dead local link, a malformed workflow, a shell bug or a secret is stopped at commit time and in CI, and one command repairs everything that can be repaired mechanically. This carries the models' two-file hook arrangement: a read-only gate configuration that is installed as the commit hook and may only report, and a separate mutating configuration that is never installed and runs only from the fix recipe.

**Adversarial review:** Key moments: at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which hook in the gate configuration can modify files; which hook never matches any file; what a contributor on macOS sees differently; whether the secret scan fires on a planted secret.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] The gate configuration runs the models' hooks: the built-in file checks, editor-config check, Markdown lint, typo check (report only), offline link check with an online variant at a manual stage, shell lint, workflow lint, and the secret scan supplied by the shared tooling package
- [x] Local hooks that wrap repository gates call Justfile recipes; clippy is deliberately not a hook
- [x] Every remote hook is pinned to a full commit hash with a version comment
- [x] The fix configuration holds every fixer and nothing in the gate configuration modifies files
- [x] Markdown lint, typo and link-check configuration match the models, with exclusions for generated, vendored and scratch directories
- [x] Recipes exist for: lint (all hooks, all files), fix, hook installation (primary checkout only), document checks, and the online link check
- [x] A deliberately introduced typo, trailing whitespace and broken relative link each fail the lint recipe; the fix recipe repairs what is repairable; evidence quoted in the hand-back
- [x] The setup action caches and prepares the hook environments
- [x] Lint is in the ordered check list and the check command ends green
- [x] CI has a `documents` job running lint and the document checks on Linux
- [x] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model

## Hand-back

Commits: `33f3dd7` (the ticket) and the commit carrying this hand-back (review fixes). Both are on `complete-bootstrap`, draft PR #2.

### What was built

- **`.pre-commit-config.yaml`** is the read-only gate, installed as the commit hook. It runs:
  - the local hooks, through `just`: `fmt-check`, `toml-check`, `deps-unused`, `py-lint` and `py-typecheck`;
  - the builtin file checks (large files, case conflict, shebangs, JSON, merge conflict, TOML, YAML, private key);
  - editorconfig-checker v3.11.3, markdownlint-cli2 v0.24.0, typos v1.51.1 (report only, `--force-exclude`), lychee 0.24.2 (offline, plus a manual-stage `lychee-online`), shellcheck v0.11.0.1, actionlint v1.7.12, and ripsecrets v0.1.11 with `bg-ripsecrets` as the entry;
  - nothing that modifies files.

  Clippy is deliberately not a hook. Every remote hook is pinned to a full SHA with a version comment, each SHA dereferenced against its tag with `gh api` on 2026-11-11. The revisions come from pachinko, which is newer than alliumpy for editorconfig, markdownlint and typos.

  The validators for docs (ticket 07) and agent files (ticket 09) join when those trees exist.
- **`.pre-commit-fix.yaml`** holds every fixer and is never installed: cargo fmt, taplo fmt, ruff format, ruff fix, `cargo shear --fix` for the root and for `fuzz`, end-of-file, trailing whitespace, markdownlint `--fix` (with `pass_filenames: false`, as pachinko has it), and typos `--write-changes`.
- **Exclusions.** `.markdownlint-cli2.jsonc`, `_typos.toml` and `lychee.toml` are the models' files. All three hook and lint configurations exclude `target`, `.pixi`, `.tools`, `ai_tmp`, `dist`, `fuzz/target`, `.scratch/` (tracked but ignored ticket scratch) and the lockfiles.
- **Recipes.**
  - `lint` runs every gate hook over every file.
  - `fix` runs the fix config twice, then clippy `--fix`, then `lint`.
  - `install-hooks` refuses in a linked worktree; it installs the shim and prepares both configurations.
  - `check-docs` runs markdownlint, typos and lychee. `bg-validate-docs` joins in ticket 07.
  - `check-links-online` covers external links and needs the network.
- **Wiring.**
  - `initialize.sh` runs `install-hooks` in a primary checkout only.
  - prek 0.5.7 is pinned in pixi and verified on both platforms.
  - `.lycheecache` is gitignored.
  - `lint` is second in the check list, as in alliumpy.
  - The setup action caches `PREK_HOME` (keyed on both hook configs and `pixi.lock`) and runs `install-hooks`.
  - CI has a `documents` job running `lint` and `check-docs` on Linux.

### Evidence

Everything below is under `ai_tmp/evidence/05/`. Planted files were staged temporarily, because `prek --all-files` reads the index, then removed.

- **Gate controls.** Each planted defect made `just lint` exit 1:
  - a typo: `typos … Failed`, with `` `teh` should be `the` `` and `` `recieve` should be `receive` ``;
  - trailing whitespace in `.md`: `markdownlint … MD009/no-trailing-spaces`;
  - trailing whitespace in `.txt`: `EditorConfig … Failed`;
  - a broken relative link: `lychee … [ERROR] …/docs/does-not-exist.md … File not found`;
  - a planted fake `ghp_` token: `ripsecrets found credential material; the matched values are suppressed`, with no secret in the log;
  - a workflow using `github.event.issue.title` inline: actionlint `potentially untrusted … [expression]`;
  - `rm -rf $DIR/*`: shellcheck `SC2115` and `SC2086`.
- **Fix.**
  - `just fix` repaired trailing spaces in `.md` and `.txt` and a missing final newline, after which `just lint` passed.
  - After the review fix, it rewrote `teh recieve` to `the receive`.
  - A broken link is not mechanically repairable, so it stays a lint failure.
- **The commit hook.** In this linked worktree, `just install-hooks` fails with `this is a secondary worktree; run it once from the primary checkout`. In a fresh primary clone, `just initialize` installed the prek shim and `just check` passed with an empty status. A `git commit` there of a file containing `teh` was blocked by `typos … Failed`, and HEAD was unchanged.
- **Hook matching.** Every gate hook reports Passed on the real tree, except `check-json`, which has no `.json` file yet and reports `Skipped`.
- **Checks.** `just check` ends `All checks passed and the worktree is unchanged.` CI run 42998601303 (`33f3dd7`) was green on all 12 jobs, the new `documents` job included.

### Adversarial review (Codex `gpt-6-astra`, triage by a separate Claude Sonnet subagent)

End of ticket, round 1:

1. **markdownlint `--fix` lacks `pass_filenames: false`**, so parallel batches race on the same files (conformance). **Valid.** Added it, with pachinko's reason.
2. **No typos fixer, so `just fix` cannot repair typos.** Both lenses reported it. **Valid.** Added typos `--write-changes` to the fix config, with a control.
3. **`cargo shear --fix` skips the fuzz crate** (conformance). **Valid.** Added `cargo shear --fix fuzz`.

### Open points

- **`check-json`** matches no file yet. It is kept, as in both models, for the first `.json` file.
- **macOS differences.** Hook environments build per platform: ripsecrets compiles with rustup, and editorconfig-checker and actionlint build with Go under prek's cache. On a cold cache the first `just install-hooks` on macOS downloads and builds those, as on Linux. The CI documents job runs on Linux only; the macOS `check` leg runs `lint` through `just check`.
- **Model gap.** Both models' fix configs lack the typos and fuzz-shear fixers. Worth upstreaming.

### Maintainer steps

None for this ticket.
