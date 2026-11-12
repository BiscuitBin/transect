# 02: Rust quality gate with the panic-free lint policy

**What to build:** Any Rust change that could panic in, or otherwise degrade, a host application is rejected by the gate before review. The workspace lint policy from the model repositories is adopted in full (unsafe forbidden, pedantic and cargo lint groups, missing docs, exhaustive-type lints) and its panic-related lints are the enforcement of the never-raise rule: unwrap, expect, panic, unreachable, todo, unimplemented and unchecked indexing are rejected outside test code. Around it sit the rest of the models' Rust gates: formatting, TOML formatting and linting, code metrics, feature-powerset check, tests under nextest plus doctests, a 90% line-coverage floor, and warning-free API docs. Each gate is a Justfile recipe, is appended to the ordered check list, and runs in CI.

The models keep every lint at warn and let the clippy recipe promote warnings to errors; keep that arrangement. Note that indexing is not in the models' lint list and is an addition here.

**Adversarial review:** Key moments: after the lint policy is in place and before the remaining gates are wired; and at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which panic path the policy still lets through outside tests; which gate passes vacuously on near-empty crates; whether any lint was weakened or suppressed to get green.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] Workspace lint tables match the models' policy, plus the indexing lint; both crates inherit them
- [x] The clippy configuration allows the panic-family lints inside tests only, and carries the models' thresholds and the ban on unordered hash collections
- [x] A deliberate unwrap, expect, panic, todo and unchecked index in non-test code of either crate each makes the clippy recipe fail; the evidence is quoted in the hand-back and the violations are not committed
- [x] Recipes exist for: format, format check, TOML check, clippy, metrics, feature powerset, test, doctests, coverage with the 90% floor, API docs with warnings denied
- [x] Formatter, TOML formatter, metrics and nextest configuration match the models
- [x] Lint suppressions are only allowed in the expect-with-reason form
- [x] The new gates are in the ordered check list and the check command ends green on a clean worktree
- [x] CI has a `rust` job running these gates (tests on Linux and macOS, the rest on Linux) and a `coverage` job that uploads the coverage report
- [x] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model

## Hand-back

Commits: `7ab822b` (the ticket), `1be2111` (moment-2 round-1 fixes), and the commit carrying this hand-back (round-2 fixes). All are on `complete-bootstrap` (draft PR #2).

### What was built

- **Lint policy.**
  - `[workspace.lints]` is alliumpy's table verbatim, plus two lints the models lack: `clippy::indexing_slicing` and `clippy::integer_division_remainder_used`.
  - Both crates use `[lints] workspace = true`.
  - `clippy.toml` is pachinko's: the `allow-*-in-tests` keys, its thresholds, and the HashMap/HashSet ban. To it are added `disallowed-macros` for `assert!`, `assert_eq!` and `assert_ne!` and their `debug_` forms. Test modules lift that ban with `#[expect(clippy::disallowed_macros, reason = "...")]`.
  - The `clippy` recipe rejects any inner `#![allow` before running clippy, including one inside a multiline `cfg_attr`.
- **Gates.**
  - The `features` recipe runs `cargo hack check` and also `cargo hack clippy` over the feature powerset.
  - Configs: rustfmt, taplo, nextest (pinned to 0.9.150) and rustqual come from pachinko.
  - Recipes added: `format`, `fmt-check`, `toml-check`, `clippy`, `metrics`, `features`, `test-doc`, `coverage` (90% line floor) and `doc` (`-D warnings --cfg docsrs`).
- **Check list.** It is now in alliumpy's order: check-toolchain, lock-check, fmt-check, toml-check, clippy, metrics, features, test-doc, coverage, doc. `build` and `test` from ticket 01 left the list: `coverage` runs every nextest test, and `test-doc` runs the doctests.
- **Pins.** cargo-llvm-cov 0.9.1 and taplo 0.10.0 were added to pixi, and rustqual 1.8.3 to `tools-source.txt` (a signed quickinstall build exists, so no compile). All were verified on 2026-11-11.
- **CI.** The `rust` job runs on an ubuntu/macOS matrix: toolchain, lock and tests on both, every other gate on Linux only. The `coverage` job uploads the lcov report.

### Evidence

Every deliberate violation below was planted in non-test code, run, recorded in `ai_tmp/evidence/02/`, and reverted. None was committed.

- **Panic-family lints** (`clippy-positive-controls.txt`). In both `libtransect` and `transect`, each of `Some(1_u8).unwrap()`, `.expect("x")`, `panic!("x")`, `todo!()` and `[1_u8, 2][usize::from(n)]` made `just clippy` exit 101. Each reported its own lint exactly once: `clippy::unwrap_used`, `expect_used`, `panic`, `todo` and `indexing_slicing`. That is 10 of 10.
- **Test code is exempt** (`clippy-test-code-allowed.txt`). `unwrap` and `v[0]` inside `#[cfg(test)]` leave `just clippy` at exit 0.
- **Suppressions** (`suppression-controls.txt`), on `o.unwrap()`:
  - no attribute → exit 101 (`used unwrap() on an Option value`);
  - `#[allow(..)]` → exit 101 (`#[allow] attribute found` and `allow attribute without specifying a reason`);
  - `#[allow(.., reason)]` → exit 101;
  - `#[expect(..)]` → exit 101 (`expect attribute without specifying a reason`);
  - `#[expect(.., reason = "positive control")]` → exit 0.
- **Assertions, inner allows and division** (`assert-and-inner-allow-controls.txt`):
  - `assert!`, `assert_eq!` and `debug_assert!` in production code → exit 101 (`use of a disallowed macro core::assert` and the like);
  - an inner `#![allow(clippy::panic, reason = ..)]` → exit 1 (`clippy: inner #![allow] attribute found`);
  - the same attribute in rustfmt's multiline `#![cfg_attr(not(test), allow(..))]` layout → exit 1;
  - `n / d` → exit 101 (`use of / has been disallowed in this context`).
- **The other gates are not vacuous** (`gate-positive-controls.txt`):
  - A 12-line untested function made `just coverage` fail at 37.78% lines against the 90 floor.
  - A broken intra-doc link failed `just doc` with `unresolved link to does_not_exist`.
  - A misformatted function failed `just fmt-check` with `Diff in …`.
  - Nesting depth 6 failed `just metrics` with `nesting depth 6 in deep` and a 16.0% quality score.
  - The clean tree has 100% line coverage over 13 lines. `nextest` ran 2 tests, one per crate. rustqual analysed 2 functions.
- **Checks.** `just check` ends `All checks passed and the worktree is unchanged.` CI run 42993448477 (`7ab822b`) and run 42994247328 (`1be2111`) were green: `check` and `rust` on ubuntu and macOS, plus `coverage`.

### Adversarial review (Codex `gpt-6-astra`, triage by separate Claude Sonnet subagents)

**Moment 1** (lint policy, before the remaining gates), round 1:

1. **`assert!` in production is unlinted.** Both lenses reported it. **Valid.** First handled by correcting the comment that overstated the enforcement, then fixed for real at moment 2.
2. **An inner `#![allow(.., reason)]` bypasses `allow_attributes`.** **Valid.** First documented in pachinko's words, then enforced at moment 2.
3. **`module_name_repetitions = "allow"` weakens pedantic.** **Invalid.** It is verbatim in alliumpy's table, and it is a table setting, not an in-code suppression.

**Moment 2** (end), round 1:

1. **Assertions remain a panic path, and `debug_assert!` was wrongly recommended.** Both lenses reported it. **Valid.** Fixed with `disallowed-macros` plus a reasoned `#[expect]` on each test module, with controls.
2. **Panics behind `cfg(not(feature))` are never linted.** **Valid.** Fixed: `features` now also runs `cargo hack clippy --feature-powerset`. The finding's macOS half is **invalid**: the `check` job runs `just clippy` on macOS.
3. **The inner-allow hole is still open.** **Valid.** Fixed with the grep gate in `clippy`.
4. **The `check` job duplicates every gate on macOS** (conformance). **Out of scope**: ticket 10 owns the final job layout. When it slims that job, it must keep clippy on macOS.

**Moment 2**, round 2 (the last round allowed):

1. **The grep misses rustfmt's multiline `cfg_attr`.** Both lenses reported it. **Valid.** Fixed with a whole-file join before matching, with a control.
2. **Integer division panics.** **Valid.** Fixed with `integer_division_remainder_used`, with a control. Arithmetic overflow is handed back below.

### Open points

- **Overflow.** Arithmetic overflow from `+ - * << >>` and negation panics in debug builds and wraps in release. It is not linted, because `arithmetic_side_effects` flags every `+`. Decide when the client has real arithmetic; ticket 07's lint-policy decision should record this.
- **Integration tests.** Files under `tests/` will need `#![expect(clippy::disallowed_macros, reason = "...")]` to assert. The grep gate does not match `expect`, so this works.
- **Beyond the models.** The assertion ban, the division lint, the inner-allow gate and the feature-powerset clippy all go beyond both models and are worth upstreaming.
- **Process.** Post-push fixes are separate `Ticket 02:` commits, because force-push is not permitted in this session.

### Maintainer steps

None for this ticket.
