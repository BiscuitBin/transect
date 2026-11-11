# 01: Foundation: workspace, toolchain, first green CI

**What to build:** A contributor clones the repository, runs one initialize command and one check command, and gets a green result; the same check runs green in CI on Linux and macOS. The Cargo workspace holds two pure-Rust crates, `libtransect` (the core) and `transect` (the public Rust client API, depending on the core, never the reverse), each with exactly one documented public item (a version accessor) and a doctest. Tooling follows the model repositories (alliumpy and pachinko): a pinned Rust toolchain managed by rustup, a pixi environment declared in the root Python project file holding the developer tools at exact pins, tool pin lists for binaries pixi cannot supply, and a Justfile that is the only interface to every command. The `biscuit-games-tooling` package is adopted as in the models, so the check command is its project-check runner over an ordered recipe list that starts minimal (toolchain check, lock check, build, test) and ends by proving the worktree is unchanged. CI starts here: a composite setup action and a workflow that runs the minimal check on both operating systems, so later tickets each add their own job.

Everything shares one workspace version, Apache-2.0, edition 2024. The Python binding crate, `transectpy`, is not created here (ticket 04). No queue, database or schema design appears anywhere.

**Adversarial review:** Key moments: after the tool pins, pixi environment and Justfile are in place and before CI is added; and at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which recipe or setup step works only on the author's machine or only on one operating system; which pin is not actually pinned; whether the minimal check can pass while something is broken; what later tickets will be forced to rewrite.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] The workspace builds `libtransect` and `transect`; `transect` depends on `libtransect`; each exposes only a documented version item with an asserting doctest
- [ ] One workspace version, licence, edition, minimum Rust version, repository URL and authors are declared once and inherited by both crates
- [ ] The Rust toolchain is pinned in a toolchain file; a recipe refuses to run when cargo is not rustup's proxy for that pin
- [ ] The pixi environment is declared in the root Python project file (tooling only, not a package), locked, for Linux x86-64 and macOS arm64, with exact pins and with Rust deliberately absent
- [ ] Tool pin lists and an install recipe put the remaining tools in a gitignored per-worktree directory
- [ ] The Justfile provides, at least: list, initialize, toolchain install and check, tool install, sync, lock, lock check, build, test, clean-worktree check, and check
- [ ] The check command runs the ordered recipe list through the project-check runner and prints the models' success line on a clean worktree
- [ ] Root configuration carried from the models exists: editor config, git attributes, ignore rules (each entry with a reason, including the agent scratch directory and local ticket scratch), licence file
- [ ] Stub README, CHANGELOG and agent-instruction files exist and say they are placeholders (tickets 09 and 12 own the final versions)
- [ ] A composite setup action reproduces the models' steps (pixi, toolchain, build cache, tool cache, tool install, sync)
- [ ] A CI workflow runs the minimal check on Linux and macOS for pull requests and pushes to main, with SHA-pinned actions, read-only permissions, a concurrency group and timeouts
- [ ] From a fresh clone, initialize then check ends green locally, and the CI run for the ticket's branch is green on both operating systems
- [ ] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model
