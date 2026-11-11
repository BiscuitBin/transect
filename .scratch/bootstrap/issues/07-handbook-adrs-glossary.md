# 07: Handbook, ADRs and glossary

**What to build:** A newcomer or an agent can read what Transect's application client is, which rules are fixed, which questions are still open, and what each domain word means, and a validator keeps those pages honest. This carries the models' handbook: a documentation tree organised by purpose (project, tutorials, how-to, explanation, reference, operations, decisions), per-page front matter, and a manifest in which every topic is owned by exactly one page, enforced by the shared tooling's documentation validator.

The decisions record what is already settled; an open-decisions page is the single register of what is not, and it must list exactly the stubs created in ticket 06 without proposing answers.

**Adversarial review:** Key moments: after the decisions and the open-decisions page are drafted, before the rest of the handbook; and at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which page states as decided something that is undecided, or the reverse; which page describes something that does not exist; whether the two shaping rules are stated precisely enough to test against; whether the register and the stubs match.

**Blocked by:** 01, 06

**Status:** ready-for-agent

- [x] The handbook tree, index page and manifest exist in the models' shape and the documentation validator passes
- [x] Project pages cover purpose and scope (what the client is, that the collector lives elsewhere, what this repository does not do) and a repository map
- [x] The glossary defines at least: table, state table, time series table, column, row, ingest queue, data writer, local database, collector, host application; and names words to avoid
- [x] A decision records the never-raise, never-block rule: the client must not raise into or block the host application, in line with established practice for loggers and metrics clients
- [x] A decision records the fork-safety rule: correct behaviour under forked worker pools such as gunicorn is a requirement, with the mechanism left open
- [x] Decisions record crate layering (core, Rust client, Python binding, and the allowed dependency direction), the lint policy as enforcement of never-raise, the dependency policy, single shared versioning, and the supported platforms (Linux and macOS)
- [x] An open-decisions page lists the ingest queue mechanism, the local database format and schema evolution as undecided, states what each blocks, and offers no design; it also records the open point of whether fork handling will need unsafe code
- [x] Every UNDECIDED marker in the core corresponds to one entry on the open-decisions page and the reverse
- [x] Decisions follow the models' numbered format and are indexed
- [x] Reference and how-to pages exist for what already works (commands, quality gates, local development) and describe nothing that does not exist
- [x] The documentation validator is a recipe, a hook, part of the ordered check list, and the check command ends green
- [x] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model

## Hand-back

Commits: `35a6607` (the ticket) and the commit carrying this hand-back (moment-2 fixes). Both are on `complete-bootstrap`, draft PR #2.

### What was built

- **The handbook.** `docs/` follows alliumpy's shape:
  - `README.md`, the documentation map;
  - `manifest.yml`, 21 pages and 22 canonical topics, each owned once;
  - project: purpose and scope, repository map, glossary, open decisions;
  - tutorials: clone to green;
  - how-to: develop locally;
  - explanation: architecture;
  - reference: commands, quality gates;
  - operations: troubleshooting;
  - decisions: an index and nine records.

  Every page carries front matter equal to its manifest entry, and every page is reachable from the map.
- **Decisions.** Each follows the models' numbered shape (context, decision, consequences, what would reopen it), and the index lists them all:
  - 0001: never raise, never block;
  - 0002: fork safety as a requirement, mechanism open;
  - 0003: crate layering;
  - 0004: the lint policy as the enforcement of never-raise;
  - 0005: dependency policy;
  - 0006: one version;
  - 0007: Linux and macOS, separating what is gated from what is intended to ship;
  - 0008: tool manager;
  - 0009: hooks.
- **The register.** `docs/project/open-decisions.md` is the single register.
  - Under "Undecided areas" it lists the ingest queue, the local database and schema evolution. Each entry names its placeholder file and states what it blocks, with no answer or shortlist.
  - Under "Open points" it lists unsafe code for fork handling, caller misuse, data the client cannot accept, and arithmetic overflow (carried from ticket 02).
  - The data writer is recorded as settled but not implemented.
- **The glossary** defines every required term (table, state table, time series table, column, row, ingest queue, data writer, local database, collector, host application) and names the words to avoid.
- **`scripts/check_undecided.py`**, written test-first in six slices in `tests/scripts/test_check_undecided.py`, with the recipe `check-undecided`. It fails when:
  - a `//! UNDECIDED:` marker under `crates/` has no entry in "Undecided areas";
  - an entry has no marker;
  - an entry appears twice.

  Paths under "Open points" do not count.
- **Wiring.**
  - `check-docs` now runs `bg-validate-docs` after markdownlint, typos and lychee.
  - Two hooks were added: `validate-docs` (through `pixi run --frozen`) and `check-undecided`.
  - The check list gains `check-docs` and `check-undecided` after `version-check`, as in alliumpy.
  - CI's `documents` job runs both.
  - The `Cargo.toml` and `rustqual.toml` comments now name decisions 0006 and 0004.

### Evidence

Everything below is under `ai_tmp/evidence/07/`.

- **The validator.** `bg-validate-docs` reports `Validated 21 pages and 22 canonical topics.` With an orphan page added, it reported `missing from manifest.yml` and `not reachable from docs/README.md`.
- **The marker check.** `just check-undecided` reports `3 UNDECIDED markers match the register`. It fails on each control:
  - the marker removed from `schema_evolution.rs` → `lists crates/libtransect/src/schema_evolution.rs … but its first line is not the UNDECIDED marker`;
  - a register entry for a nonexistent `retries.rs` → the same message for that file.
- **Docs match reality.**
  - `just --summary` compared with the recipes named in `docs/reference/commands.md`: none missing in either direction.
  - The quality-gates table matches the `pyproject.toml` check list exactly, in order.
- **Checks.** `just check` ends `All checks passed and the worktree is unchanged.` CI run 43002535341 (`35a6607`) was green on every job.

### Adversarial review (Codex `gpt-6-astra`, triage by separate Claude Sonnet subagents)

**Moment 1** (decisions and register drafted), round 1:

1. **0001 limited never-block to recording calls.** Both lenses reported it. **Valid.** Now it covers every call: recording, construction, configuration, flushing and shutdown.
2. **Duplicate register entries passed `check_undecided`** (conformance). **Valid.** Fixed test-first: the duplicate is reported.
3. **0002 claimed a fork harness that does not exist yet.** Both lenses reported it. **Valid.** Reworded as future; ticket 08 updates it.
4. **The map claimed `check-docs` enforces the manifest.** **Invalid**: already resolved, because `check-docs` runs `bg-validate-docs`.
5. **0003 said "down the table".** **Valid.** Now "up the table".
6. **0005 put yanked releases under the offline gate.** Both lenses reported it. **Valid.** Moved to `just audit`.

**Moment 2** (end), round 1:

1. **The purpose page called the agent contract complete.** Both lenses reported it. **Valid.** It now says the contract is a placeholder.
2. **0005 omitted the models' exceptions.** **Valid.** Added the snapshot and fuzz `--locked` exceptions and the fuzz crate's own manifest range.

### Open points

- **Unconfirmed definitions.** "State table" and "time series table" have no source beyond ticket 12's one sentence. They are defined by role only, and the maintainer should confirm them.
- **Unsettled behaviour.** Caller misuse, the handling of unacceptable data, and arithmetic overflow are recorded as open points rather than decided.

### Maintainer steps

- Confirm the glossary definitions of state table and time series table.
