# 10: Integration: one `just check`, one required CI check

**What to build:** After the parallel lanes have merged, one local command and one CI status tell the whole truth about the repository. The ordered check list contains every gate from tickets 02 to 09 in a deliberate order (cheap and offline first), the command ends with the success line on a clean worktree, and CI aggregates every job behind a single job that is the only required status check and fails if any job it needs failed, was cancelled or was skipped.

This is where conflicts in the files the lanes shared (the Justfile, the check list, the hook configurations, the workflow, ignore rules) are resolved and where gaps between lanes are found.

**Adversarial review:** Key moments: after the lanes are merged and the full check first runs green; and at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which gate from tickets 02 to 09 is missing from the check list or from CI; which job can be skipped while the aggregate stays green; what differs between a fresh clone and the author's worktree; what the lanes each assumed the other would do.

**Blocked by:** 02, 03, 04, 05, 06, 07, 08, 09

**Status:** ready-for-agent

- [x] The ordered check list holds every gate once, in the models' order with the Python gates placed as in alliumpy
- [x] From a fresh clone, initialize then check ends with the success line and an empty worktree status, on Linux and on macOS
- [x] Every gate in the list also runs in some CI job, and each CI job ends by proving the worktree is clean
- [x] A single aggregate job needs every other job and is green only when all succeeded
- [x] The reference pages for commands and quality gates match the actual recipes and list
- [x] The repository map, agent file project map and skills name only things that exist
- [x] Nothing in the Rust client or the Python package beyond the version item has appeared, and the open-decisions register still matches the stubs
- [x] Any gate found to pass vacuously is given a positive control or reported in the hand-back
- [x] Repository settings that need a maintainer (marking the aggregate job as required, branch protection) are listed in the hand-back, not changed
- [x] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model

## Hand-back

Commits: `173500a`, `1dd5cc8`, `6ab8c68`, and the commit carrying this hand-back. All are on `complete-bootstrap`, draft PR #2.

There were no parallel lanes: tickets 01–09 ran in order on one branch. "Merging the lanes" was therefore a gap audit of the check list, CI, docs and the agent file against what exists.

### What was built

- **`ci-ok`**, the aggregate job. It `needs` every other job (`check`, `rust`, `python`, `wheel-smoke-py311`, `coverage`, `deny`, `documents`), runs `if: always()`, and fails when any needed result is `failure`, `cancelled` or `skipped`. It is the one check branch protection should require.
- **Every job proves a clean worktree.**
  - The `check` job now runs `just initialize`, then `just check`, then a baseline-free `just check-clean`, on ubuntu and macOS. This is the contributor's first-run path, exercised in CI.
  - `wheel-smoke-py311` keeps its venv in `$RUNNER_TEMP`, removes `dist/`, and ends with `git status --porcelain` empty.
- **Docs.** The quality-gates page describes `ci-ok` and the clean-worktree proofs.
- **Pool helper.** A one-line docstring now states what the pool helper's deadline does not cover.

### Gap audit

- **Check list.** 25 gates, each once. The 22 shared with alliumpy are in alliumpy's relative order, and the Python gates sit where alliumpy places them. Three gates are additions: `fuzz-build` (required by ticket 03), `wheel-smoke-floor` (ticket 04) and `check-undecided` (ticket 07).
- **CI coverage.** Every gate runs in a named job:
  - `rust`: check-toolchain, lock-check, fmt-check, toml-check, clippy, fuzz-build, metrics, features, test (which includes `test-doc`'s doctests), snapshots-check, doc, deps-unused;
  - `coverage`, `deny`;
  - `python`: the seven Python gates;
  - `documents`: lint, check-docs, check-agents, check-undecided.

  The `check` job also runs the whole list on both platforms.
- **Docs match reality.**
  - The `docs/reference/commands.md` recipe names equal `just --summary`, both ways.
  - The quality-gates table equals the check list, in order.
  - The `AGENTS.md` recipe names all exist.
  - The repository map, the AGENTS project map and the skills name only existing paths.
  - `just check-undecided` reports `3 UNDECIDED markers match the register`.
- **Nothing leaked.** The Rust client and the Python package still expose only their version (`test_nothing_but_the_version_is_public`).
- **No vacuous gates.** Every gate has had a positive control in its own ticket. `snapshots-check` passes with no snapshots, by design. `check-json` has no JSON file to match.

### Evidence

- **Fresh clone, macOS.** `git clone --branch complete-bootstrap` into the session scratchpad, then `just initialize && just check`: exit 0, `All checks passed and the worktree is unchanged.`, and `git status --porcelain` was empty.
- **Fresh clone, Linux and macOS in CI.** Run 43009449860 (`6ab8c68`): on both ubuntu-latest and macos-latest, the `check` job printed `Ready. Next: just check.`, then `All checks passed and the worktree is unchanged.`, then `The Git worktree is clean.`
- **CI.** Run 43008446442 (`1dd5cc8`) and run 43009449860 (`6ab8c68`) were green on all 13 jobs, `ci-ok` included.

### Adversarial review (Codex `gpt-6-astra`, triage by a separate Claude Sonnet subagent)

**Moment 1** (integrated and green), round 1. Conformance reported no findings. Breakage reported two:

1. **`just check` succeeds on an already-dirty worktree**, because biscuit-games-tooling compares against the baseline taken at the start. The local recipe is **invalid as a defect**: both models use the same semantics, and `AGENTS.md` separately requires an empty `git status` at hand-back. The CI part is **valid**: the `check` job now ends with a baseline-free `just check-clean`.
2. **The pool helper can hang while unpickling a result whose `__reduce__` blocks.** **Invalid as a defect**: it is not a realistic harness input, and a supervisor process would test a different situation. A docstring note was added.

**Moment 2** (end), round 1. Both lenses reported no findings.

### Open points

- **Proving the aggregate fails.** No run with a failing job has exercised `ci-ok` yet; that would need a deliberately red push. Its condition is the alliumpy model's, unchanged.
- **macOS minutes.** The `check` job duplicates the split jobs' gates, and on macOS that costs billed minutes. It is the only place macOS runs `lint`, `clippy`, `fuzz-build` and `just initialize`.

### Maintainer steps

- Mark `ci-ok` as the only required status check on `main`.
- Enable branch protection on `main`: require pull requests and the `ci-ok` check, and disallow force pushes.
