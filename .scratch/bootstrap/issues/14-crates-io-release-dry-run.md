# 14: crates.io release workflow, dry-run only

**What to build:** A maintainer can trigger the Rust release pipeline and see that `libtransect` and `transect` would package and publish cleanly, in dependency order, under the single shared version, without anything being published. Neither model repository publishes to crates.io, so there is nothing to copy for the publish step itself; pachinko's tag-driven release workflow and release-tooling configuration are the closest shape, and its per-crate tags and changelog sections are replaced here by one version, one tag and one changelog. The binding crate is never published to crates.io.

Because this ticket has no direct model, choices that are not forced (the release tool, how the unpublished core dependency is verified in a dry-run, API compatibility checking) are proposed in the hand-back for the maintainer to confirm.

**Adversarial review:** Key moments: after the publishing arrangement is proposed and before it is built, so the maintainer sees a reviewed proposal; and at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: any path by which a dry-run or a mistaken tag could publish; where the shared version can drift; what happens when the core publishes and the client fails; how the two release workflows interact on one tag.

**Blocked by:** 10, 12

**Status:** ready-for-agent

- [x] The two publishable crates carry complete registry metadata (description, readme, keywords, categories, docs settings) and the binding crate is marked unpublishable
- [x] A recipe performs a packaging dry-run for both crates in dependency order and is documented as needing the network
- [x] Release-tooling configuration bumps the shared version everywhere it appears (workspace, wheel manifest, changelog heading) and creates one tag, with push and publish off by default
- [x] A recipe or gate fails when the version differs between any of those places
- [x] The workflow runs on version tags and on demand, re-runs the full check, and applies the same guards as the Python release: tagged commit on main, tag equals version, non-empty changelog section
- [x] The publish step sits behind a protected environment and cannot run in a dry-run
- [x] How this workflow and the Python release workflow share one tag is defined (one workflow or two, and their order) and written down
- [x] An on-demand dry-run has completed green and is quoted in the hand-back, or the hand-back states that authorisation to run it was not given
- [x] The release how-to page covers the Rust side, including the maintainer-only steps that remain (registry token or trusted publishing, protected environment)
- [x] A decision records the publishing arrangement and the check command ends green
- [x] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model

## Hand-back

Commits on `complete-bootstrap`: the ticket 14 commit, a temporary `pull_request` trigger for the pre-merge dry run, and the commit carrying this hand-back (review fixes, trigger removed). Draft PR #2.

### The proposal and the maintainer's choices

Before anything was built, the publishing arrangement was proposed and reviewed (moment 1, below), then confirmed by the maintainer (2026-11-11), who chose:

- **Two workflows.** `release-pypi.yml` and `release-crates.yml` run independently on one `v<version>` tag, each behind its own environment approval: approve `crates-io` first, then `pypi`.
- **First publish by hand.** The first crates.io publish is done from a maintainer machine. CI has no token path.
- **Semver deferred.** API compatibility checks are deferred to the open-decisions register.
- **No GitHub Release.** None is created for now; the question is on the register.

### What was built

- **Publishing.**
  - `libtransect` and `transect` are publishable: the workspace `publish = false` is gone. They carry `documentation` (docs.rs), `readme`, keywords, categories, docs.rs settings, and a copy of `LICENSE`, so the package ships the licence text.
  - `transectpy` stays `publish = false`.
- **cargo-release 1.1.7**, pinned in `tools.txt`. `[workspace.metadata.release]` sets `shared-version` and one consolidated commit on `release/*`, with `tag`, `push` and `publish` off.
  - The `transect` crate's `pre-release-replacements` move the wheel manifest version, the fuzz crate's requirement and the changelog heading. Each must match exactly once.
- **`just package-dry-run`** (network) runs `cargo publish --dry-run --workspace --locked`. It is listed with the network recipes in `AGENTS.md` and the commands reference.
- **`version-check`**, test-first. It also fails on:
  - a `[workspace.dependencies]` path requirement;
  - the fuzz crate's path requirement;
  - the newest dated changelog heading, when any of them differs from the version.
- **`.github/workflows/release-crates.yml`**: tag and dispatch triggers, with `publish` defaulting off.
  - **`verify`** runs `just initialize`, `just check` and `just package-dry-run`, then the PyPI workflow's guards.
  - **`publish`** runs only when publishing, behind the `crates-io` environment, with `contents: read` and `id-token: write`. It:
    - checks out the verified commit and re-checks the tag after approval;
    - authenticates with `rust-lang/crates-io-auth-action`;
    - publishes the core, then the client, skipping a version the index already holds.
- **Docs.**
  - Decision 0010 records the release process.
  - `docs/how-to/release.md` became "Cut a release", covering both registries.
  - Two new entries on the open-decisions register: semver checks and a GitHub Release.
  - The repository map, the decision index and the changelog are updated.

### Evidence

- **cargo-release trial**, in a scratch clone on `release/v0.1.1`. `cargo release patch --workspace --execute` produced one commit, `Release 0.1.1`. It touched `CHANGELOG.md` (`## [0.1.1] - 2026-11-11` under `## [Unreleased]`), `Cargo.lock`, `Cargo.toml` (version and both requirements), `crates/transectpy/pyproject.toml` and `fuzz/Cargo.toml`.
  - After the trial, `just lock-check` failed on `fuzz/Cargo.lock`; `just lock` refreshed it, and `lock-check` then passed.
  - `https://index.crates.io/li/bt/libtransect` still answered `404`: nothing was published.
- **Local packaging.** `cargo publish --dry-run --workspace --locked`, run with `--allow-dirty` before the commit (the recipe refuses a dirty tree), printed `Packaging libtransect v0.1.0`, `Packaging transect v0.1.0`, `Verifying` both, and `warning: aborting upload due to dry run` twice.
- **Version-check control.** Setting fuzz to `0.0.9` and adding a `## [0.2.0] - 2026-11-11` heading made `just version-check` fail with both messages; the change was reverted.
- **CI dry run.** Run 43017781368 on the temporary-trigger commit:
  - `verify` succeeded. It printed `Ready. Next: just check.`, then `All checks passed and the worktree is unchanged.`, then `Packaging`/`Verifying` both crates and `aborting upload due to dry run`.
  - Its guards printed `publish false`, `commit guard: false` (warning), `workspace version 0.1.0`, and a changelog warning.
  - `publish` was `skipped`.
- **Changelog guard cases** (`ai_tmp/evidence/14/changelog-guard-cases.sh`, bash): a dated section with notes, and a dated section with a link footer, pass. An undated heading, a heading-only section and a duplicate heading fail.
- **Gate.** `just check`: `All checks passed and the worktree is unchanged.`

### Adversarial review (Codex `gpt-6-astra`, triage by a separate Claude Sonnet subagent)

**Moment 1** (the proposal), round 1:

1. **Conformance 1 and breakage 1** (the same finding). The proposed publish job had `id-token` only, so it could not check out the private repository. **Valid.** It now has `contents: read`, checks out the verified commit and re-checks the tag.
2. **Conformance 2 and breakage 3** (the same finding). The excluded fuzz crate's requirement and lockfile would go stale after a bump. **Valid.** A replacement now covers the requirement, `just lock` is part of the procedure, and `version-check` covers the requirement.
3. **Conformance 3.** The proposal claimed cargo-semver-checks needs a published baseline, which pachinko shows is false. **Valid.** The deferral is now presented as a scope choice.
4. **Breakage 2.** Retagging after one registry had published could release different commits under one version. **Valid.** The fix adds a retagging rule and post-approval tag re-checks in both publish jobs; the PyPI one was added in ticket 13.

**Moment 2** (end), round 1:

1. **Conformance 1.** The changelog guard accepted an undated or heading-only section. **Valid.** In both workflows the guard now requires exactly one dated heading and a line that is not a heading.
2. **Conformance 2.** The how-to ran `just version-check` before the wheel was rebuilt. **Valid.** The step now runs `just check`.
3. **Breakage 1.** A bare `cargo release` cannot find the pinned binary in `.tools/bin`. **Valid.** The how-to now uses `PATH="$PWD/.tools/bin:$PATH" cargo release …`, keeping the proposal's no-wrapper rule.

The moment-2 fixes are documentation and a guard shape whose cases were tested in bash, so no second round was run.

The reviewers were asked four questions. Their answers:

- **A dry run or mistaken tag that could publish:** none remains. Tag checks key on `ref_type`, and `publish` runs only when publishing.
- **Version drift:** covered by `version-check` across the workspace, the requirements, the fuzz crate, the wheel manifest, the installed wheel and the changelog heading.
- **The core publishes and the client fails:** re-run `publish`; it skips the published core.
- **Two workflows on one tag:** they are independent and approved separately, with the order written down.

### Open points

- **Unrun edits.** The moment-2 changelog-guard change and the post-approval re-checks have not run in CI; the guard's cases were tested locally in bash.
- **Semver checks and a GitHub Release** are on the open-decisions register.
- **Licence copies.** `crates/libtransect/LICENSE` and `crates/transect/LICENSE` are copies of the root `LICENSE`, as `crates/transectpy/LICENSE` already was. Nothing checks that the copies stay identical.
- **Plan features.** Required reviewers need a public repository or GitHub Enterprise, and the pre-flight stops a release until then.

### Maintainer steps

- **Create the `crates-io` environment** with a required reviewer and deployment rules for `v*` tags and `main`.
- **First publish** of each crate by hand: `cargo publish --locked -p libtransect`, then `-p transect`, using a token scoped to new crates.
- **Then configure trusted publishing** on crates.io for both crates (`BiscuitBin/transect`, `release-crates.yml`, environment `crates-io`), and revoke the token.
- **After merge,** run `gh workflow run release-crates.yml --ref main -f publish=false` once from `main`.
