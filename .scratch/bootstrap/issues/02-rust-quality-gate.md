# 02: Rust quality gate with the panic-free lint policy

**What to build:** Any Rust change that could panic in, or otherwise degrade, a host application is rejected by the gate before review. The workspace lint policy from the model repositories is adopted in full (unsafe forbidden, pedantic and cargo lint groups, missing docs, exhaustive-type lints) and its panic-related lints are the enforcement of the never-raise rule: unwrap, expect, panic, unreachable, todo, unimplemented and unchecked indexing are rejected outside test code. Around it sit the rest of the models' Rust gates: formatting, TOML formatting and linting, code metrics, feature-powerset check, tests under nextest plus doctests, a 90% line-coverage floor, and warning-free API docs. Each gate is a Justfile recipe, is appended to the ordered check list, and runs in CI.

The models keep every lint at warn and let the clippy recipe promote warnings to errors; keep that arrangement. Note that indexing is not in the models' lint list and is an addition here.

**Adversarial review:** Key moments: after the lint policy is in place and before the remaining gates are wired; and at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which panic path the policy still lets through outside tests; which gate passes vacuously on near-empty crates; whether any lint was weakened or suppressed to get green.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Workspace lint tables match the models' policy, plus the indexing lint; both crates inherit them
- [ ] The clippy configuration allows the panic-family lints inside tests only, and carries the models' thresholds and the ban on unordered hash collections
- [ ] A deliberate unwrap, expect, panic, todo and unchecked index in non-test code of either crate each makes the clippy recipe fail; the evidence is quoted in the hand-back and the violations are not committed
- [ ] Recipes exist for: format, format check, TOML check, clippy, metrics, feature powerset, test, doctests, coverage with the 90% floor, API docs with warnings denied
- [ ] Formatter, TOML formatter, metrics and nextest configuration match the models
- [ ] Lint suppressions are only allowed in the expect-with-reason form
- [ ] The new gates are in the ordered check list and the check command ends green on a clean worktree
- [ ] CI has a `rust` job running these gates (tests on Linux and macOS, the rest on Linux) and a `coverage` job that uploads the coverage report
- [ ] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model
