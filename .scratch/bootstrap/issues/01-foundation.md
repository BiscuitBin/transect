# 01: Foundation: workspace, toolchain, first green CI

**What to build:** A contributor clones the repository, runs one initialize command and one check command, and gets a green result; the same check runs green in CI on Linux and macOS. The Cargo workspace holds two pure-Rust crates, `libtransect` (the core) and `transect` (the public Rust client API, depending on the core, never the reverse), each with exactly one documented public item (a version accessor) and a doctest. Tooling follows the model repositories (alliumpy and pachinko): a pinned Rust toolchain managed by rustup, a pixi environment declared in the root Python project file holding the developer tools at exact pins, tool pin lists for binaries pixi cannot supply, and a Justfile that is the only interface to every command. The `biscuit-games-tooling` package is adopted as in the models, so the check command is its project-check runner over an ordered recipe list that starts minimal (toolchain check, lock check, build, test) and ends by proving the worktree is unchanged. CI starts here: a composite setup action and a workflow that runs the minimal check on both operating systems, so later tickets each add their own job.

Everything shares one workspace version, Apache-2.0, edition 2024. The Python binding crate, `transectpy`, is not created here (ticket 04). No queue, database or schema design appears anywhere.

**Adversarial review:** Key moments: after the tool pins, pixi environment and Justfile are in place and before CI is added; and at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which recipe or setup step works only on the author's machine or only on one operating system; which pin is not actually pinned; whether the minimal check can pass while something is broken; what later tickets will be forced to rewrite.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [x] The workspace builds `libtransect` and `transect`; `transect` depends on `libtransect`; each exposes only a documented version item with an asserting doctest
- [x] One workspace version, licence, edition, minimum Rust version, repository URL and authors are declared once and inherited by both crates
- [x] The Rust toolchain is pinned in a toolchain file; a recipe refuses to run when cargo is not rustup's proxy for that pin
- [x] The pixi environment is declared in the root Python project file (tooling only, not a package), locked, for Linux x86-64 and macOS arm64, with exact pins and with Rust deliberately absent
- [x] Tool pin lists and an install recipe put the remaining tools in a gitignored per-worktree directory
- [x] The Justfile provides, at least: list, initialize, toolchain install and check, tool install, sync, lock, lock check, build, test, clean-worktree check, and check
- [x] The check command runs the ordered recipe list through the project-check runner and prints the models' success line on a clean worktree
- [x] Root configuration carried from the models exists: editor config, git attributes, ignore rules (each entry with a reason, including the agent scratch directory and local ticket scratch), licence file
- [x] Stub README, CHANGELOG and agent-instruction files exist and say they are placeholders (tickets 09 and 12 own the final versions)
- [x] A composite setup action reproduces the models' steps (pixi, toolchain, build cache, tool cache, tool install, sync)
- [x] A CI workflow runs the minimal check on Linux and macOS for pull requests and pushes to main, with SHA-pinned actions, read-only permissions, a concurrency group and timeouts
- [x] From a fresh clone, initialize then check ends green locally, and the CI run for the ticket's branch is green on both operating systems
- [x] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model

## Hand-back

Implemented on branch `complete-bootstrap` (draft PR #2) in commit `81a384e`, with post-push fix commits `1271998` (proxy detection) and the one carrying this hand-back. A force-push to keep one commit per ticket was refused by the session's permission policy, so fixes found after a push land as further commits prefixed `Ticket 01:`.

### Evidence

- **Fresh clone.** `git clone --branch complete-bootstrap` into the session scratchpad, then `just initialize && just check`: exit 0, ended with `All checks passed and the worktree is unchanged.`, and `git status --porcelain` was empty.
- **CI.** Run 42992336436 (https://github.com/BiscuitBin/transect/actions/runs/42992336436): `check (ubuntu-latest)` passed in 28 s and `check (macos-latest)` in 35 s. Both runners print `1.99.1-<host> (overridden by '…/rust-toolchain.toml')`. The first run (42992092773) failed on macOS only. That runner's rustup is Homebrew's, whose proxy at `/opt/homebrew/opt/rustup/bin/cargo` is neither under `~/.cargo/bin` nor the same file as `rustup`, so the proxy check now tests behaviour (`cargo +<pin> --version`).
- **Version tests bite.** With `libtransect::version()` changed to return `"0.0.0"`, `cargo test` failed `tests::the_version_is_the_manifests`. Reverted.
- **`check-toolchain` refusals** (all exit 2):
  - `RUSTUP_TOOLCHAIN=stable` → `the active toolchain is stable-aarch64-apple-darwin (overridden by environment variable RUSTUP_TOOLCHAIN); it must be 1.99.1, selected by rust-toolchain.toml`
  - a foreign cargo first on PATH, with or without `CARGO_HOME` pointed at it → `cargo resolves to …/cargo, not rustup's proxy for 1.99.1`
  - `RUSTC=<1.98.1 rustc>` → `RUSTC is set (…); it overrides the pinned toolchain, so unset it`
- **`lock-check` refusals.**
  - A workspace version bump without relocking → `cannot update the lock file … because --locked was passed`.
  - A pixi pin edit without relocking → `lock file not up-to-date with the workspace`.
- **Pins.**
  - Pixi pins were verified on linux-64 and osx-arm64 with `pixi search` on 2026-11-11: python ==3.14.10, just 1.59.0, cargo-binstall 1.26.1, cargo-nextest 0.9.150.
  - cargo-hack 0.6.45 was verified with `cargo info`.
  - Pixi 0.84.1 comes from alliumpy, the newer of the two models.
  - Every action SHA was dereferenced against its tag with `gh api`.
- **Stub `AGENTS.md`.** It does not trip biscuit-games-tooling: `bg-validate-agents` runs only through `check-agents`, which ticket 09 adds.

### Adversarial review (Codex `gpt-6-astra`, triage by separate Claude Sonnet subagents)

Moment 1 (pins, pixi and Justfile, before CI), round 1:

1. **Python was `3.14.*`, not exact.** Both lenses reported it. **Valid**; now `==3.14.10`.
2. **No `list` recipe** (conformance). **Valid**; added `alias list := default`.
3. **`check-toolchain` bypassable by pointing `CARGO_HOME` at a foreign cargo** (breakage). **Valid**. The fix was first file identity with `rustup`, then (after macOS CI) the `+toolchain` behaviour test.

Moment 2 (end), round 1. Conformance reported no findings.

1. **`RUSTC` overrides the pinned compiler unseen** (breakage). **Valid**; `check-toolchain` now refuses a set `RUSTC`.
2. **README omits the prerequisites (rustup, pixi, just)** (breakage). **Out of scope**; ticket 12 owns the README. A one-line prerequisites note was added to the stub anyway.

### Open points

- `check-toolchain`'s three hardenings go beyond both models: the behavioural proxy test, the `RUSTC` refusal, and exact Python. They are worth upstreaming.
- The models are Ubuntu-only; macOS CI is new here. Every pull-request run is cold, because cache writes happen on main only.

### Maintainer steps

None for this ticket. Branch protection and the required check belong to ticket 10.
