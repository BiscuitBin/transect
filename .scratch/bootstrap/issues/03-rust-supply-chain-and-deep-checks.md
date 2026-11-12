# 03: Rust supply chain and deep checks

**What to build:** A dependency with an unacceptable licence, source or advisory cannot enter the workspace unnoticed, and the slower verification tools are wired and proven to run even though there is nothing substantial for them to find yet. This carries the models' dependency policy (licence allow-list, crates.io as the only source, wildcard versions denied, yanked crates denied), the unused-dependency check, snapshot-test recipes, a separate fuzz workspace with one smoke target against the core, a benchmark stub, and a mutation-testing recipe.

**Adversarial review:** Key moments: at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: whether the dependency policy would really reject a bad licence, git source or wildcard; whether the fuzz target and mutation run exercise anything; which check silently skips the fuzz workspace.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] The dependency policy file matches the models, with the target list reduced to the Linux and macOS triples this project ships
- [x] A recipe checks licences, bans and sources offline; a separate recipe checks advisories and is documented as needing the network
- [x] A recipe reports unused dependencies
- [x] Snapshot recipes (check, review, accept) exist and the check passes with no snapshots present
- [x] A fuzz crate outside the workspace, with its own lockfile and a hand-copied lint table, has one smoke target exercising the core's only public item; recipes build it and run it for a bounded time on the stable toolchain
- [x] The core has one benchmark over its public item, run by a recipe and never part of the gate
- [x] A mutation-testing recipe runs over the pure-Rust crates and first proves its mutant list is not empty
- [x] Format, clippy, lock and sync recipes cover the fuzz workspace as well as the root
- [x] The offline gates (policy, unused dependencies, snapshot check, fuzz build) are in the ordered check list and the check command ends green
- [x] CI has a `deny` job for the policy check
- [x] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model

## Hand-back

Commits: `fc53996` (the ticket) and the commit carrying this hand-back (review fixes). Both are on `complete-bootstrap`, draft PR #2.

### What was built

- **`deny.toml`.**
  - It is alliumpy's file. Its targets are cut to the six Linux gnu/musl and macOS x86_64/aarch64 triples, and pachinko's comments are used.
  - It serves both dependency graphs. One narrow exception allows NCSA for `libfuzzer-sys`, which goes only into the never-shipped fuzz binary.
- **Recipes.**
  - `deny` checks licences, bans and sources offline, once for the workspace and once for `fuzz/`.
  - `audit` checks advisories. It needs the network and stays out of `just check`.
  - `deps-unused` runs `cargo shear` for the workspace and for `fuzz/`.
  - `snapshots-check`, `snapshots-review` and `snapshots-accept` use cargo-insta.
  - `bench` runs the divan benchmark over `libtransect::version`.
  - `mutants` covers `libtransect` and `transect`, and first proves the mutant list is not empty.
  - `fuzz` and `fuzz-build` use the stable toolchain with no sanitizer, an offline lock guard, and the host `--target`.
- **Fuzz crate.**
  - `fuzz/` sits outside the workspace with its own `Cargo.lock`.
  - Its lint tables are hand-copied from the root `[workspace.lints]`, the two additions included.
  - Its `smoke` target calls `libtransect::version()`. It carries a reasoned inner `#![expect(clippy::disallowed_macros)]`, because a fuzz target reports failure by panicking.
- **Recipes that now cover `fuzz/`.** `format`, `fmt-check`, `clippy` (and its inner-allow search), `lock`, `lock-check`, `lock-upgrade`, `sync`, `deny`, `audit` and `deps-unused`.
- **Check list.** It gains `fuzz-build` after `clippy` (the ticket requires it in the list; alliumpy keeps it out), and `deny`, `deps-unused` and `snapshots-check` after `doc`.
- **CI.** A `deny` job was added. The `rust` job now also runs `fuzz-build`, `snapshots-check` and `deps-unused` on Linux.
- **Pins**, all verified on 2026-11-11:
  - pixi: cargo-deny 0.20.2, cargo-insta 1.49.0, cargo-shear 1.13.4 and cargo-mutants 27.1.0;
  - `tools.txt`: cargo-fuzz 0.13.2, whose macOS binary is x86_64 and runs under Rosetta;
  - Cargo: divan 0.1.21 and libfuzzer-sys 0.4.13.

### Evidence

Every violation below was made in a throwaway copy or in the worktree and then reverted. The output is in `ai_tmp/evidence/03/`.

- **The dependency policy rejects what it should.** `cargo deny check licenses bans sources` passes on the clean tree (exit 0), and fails on each planted violation:
  - a path dependency with no version: exit 2, `error[wildcard]: found 1 wildcard dependency for crate 'transect'`;
  - `cfg-if` from git: exit 10, `error[source-not-allowed]: detected 'git' source not explicitly allowed`;
  - `ffmpeg-sys` (WTFPL): exit 4, `error[rejected]: failed to satisfy license requirements`;
  - `openssl-sys`: exit 2, `error[banned]`;
  - `libfuzzer-sys = "*"` in the fuzz crate: `just deny` fails with `error[wildcard] … for crate 'libtransect-fuzz'` and `bans FAILED`.
- **Unused dependency.** `divan` added to `transect` and never used makes `just deps-unused` fail with `shear/unused_dependency … unused dependency divan`.
- **Clippy covers the fuzz crate.** An `unwrap` planted in `fuzz_targets/smoke.rs` makes `just clippy` fail: `used unwrap() on a Result value --> fuzz_targets/smoke.rs:14:13`.
- **Mutants.** `just mutants` reports `Found 4 mutants to test … 4 mutants tested in 5s: 4 caught`; the list is `""` and `"xyzzy"` for each crate's `version`. `just mutants --file does-not-exist.rs` fails with `mutants: no mutants found; the filters select nothing`.
- **Fuzz.** `just fuzz smoke 10` reports `Done 38471776 runs in 11 second(s)`.
- **Bench.** `just bench` times `version` (median 0.94 ns). It is not in the gate.
- **Snapshots.** `just snapshots-check` passes with no snapshots present.
- **Check and CI.** `just check` runs 14 gates and ends `All checks passed and the worktree is unchanged.` CI run 42995407365 (`fc53996`) is green: `check` and `rust` on ubuntu and macOS, `coverage` and `deny`. The macOS `check` leg ran `fuzz-build` under Rosetta.

### Adversarial review (Codex `gpt-6-astra`, triage by a separate Claude Sonnet subagent)

End of ticket, round 1. Conformance reported no findings. Breakage reported two:

1. **`deny` and `audit` skip the fuzz graph.** **Valid.** Each recipe now has a second run with `--manifest-path fuzz/Cargo.toml`. That run exposed `libfuzzer-sys`'s NCSA licence, which now has a crate-scoped exception. A control was added.
2. **`deps-unused` skips the fuzz crate.** **Valid.** Added `cargo shear fuzz`.

### Open points

- **Rosetta.** cargo-fuzz's macOS release is x86_64 only, so `fuzz-build`, and with it `just check`, needs Rosetta 2 on Apple silicon. The macOS runner has it, and so does the maintainer's machine.
- **Nothing to find yet.** The mutation and fuzz runs exercise only the version item.
- **Dev-dependencies are outside the policy graph.** This is the models' `exclude-dev` choice: divan and any future test-only dependency skip `[sources]` and advisories.

### Maintainer steps

None for this ticket.
