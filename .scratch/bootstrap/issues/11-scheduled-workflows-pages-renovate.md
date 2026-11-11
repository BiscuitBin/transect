# 11: Scheduled workflows, Pages and renovate

**What to build:** The repository looks after itself between changes: advisories, fuzzing and mutation testing run weekly and report without gating merges, the Rust API documentation is published as a site from main, and every pinned version in the repository is tracked by the dependency bot. All of this carries the models' workflows and bot configuration.

**Adversarial review:** Key moments: at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which workflow has broader permissions than it needs; which pin the dependency bot cannot see; which scheduled job would fail silently for months.

**Blocked by:** 10

**Status:** ready-for-agent

- [x] An advisory workflow runs on pull requests, weekly and on demand, and is not a required check
- [x] A fuzz workflow runs each fuzz target weekly and on demand for a bounded time and uploads failing inputs
- [x] A mutation-testing workflow runs weekly and on demand and uploads its report
- [x] A Pages workflow builds the API docs site from main and deploys it, with deployment guarded so it is skipped while the repository is private
- [x] All workflows use SHA-pinned actions, read-only default permissions, the shared setup action, concurrency groups and timeouts, and pass the workflow lint
- [x] The dependency bot configuration follows the models: grouped updates, lockfile-only ranges, no automerge, dashboard approval for tool and toolchain bumps
- [x] Custom managers cover every pin the bot cannot see natively: the toolchain channel and minimum Rust version, the tool pin lists, the test-runner version, the shared tooling tag, the pixi version, hook revisions, and the maturin and uv pins
- [x] Each workflow has been run once on demand and its result is quoted in the hand-back, or the hand-back states that authorisation to run it was not given
- [x] The operations and how-to pages describe these workflows and the check command ends green
- [x] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model

## Hand-back

Commits: `720a534` and the commit carrying this hand-back. Both are on `complete-bootstrap`, draft PR #2.

### What was built

- **`audit.yml`** runs `just audit` on pull requests, weekly and on `workflow_dispatch`. It is not a `ci-ok` dependency, so it never gates a merge.
- **`fuzz.yml`** runs each target under `fuzz/fuzz_targets/` weekly and on demand.
  - Each target runs for a bounded time through `just fuzz`.
  - On failure, the job uploads `fuzz/artifacts/`.
- **`mutants.yml`** runs `just mutants` weekly and on demand and uploads `mutants.out/`. It is a report, never a gate.
- **`pages.yml`** builds the rustdoc site with `just site` on pushes to main and on demand.
  - The deploy job runs only when `github.ref == 'refs/heads/main' && github.event.repository.private == false`, so a private repository skips it rather than fails.
  - The `pages: write` and `id-token: write` permissions are granted only to the deploy job.
- **Common to all four workflows:**
  - SHA-pinned actions and `permissions: contents: read` by default;
  - the shared setup action;
  - concurrency groups and timeouts;
  - they pass actionlint through `just lint`.
- **`renovate.json`** is adapted from alliumpy.
  - Updates are grouped, ranges are `update-lockfile` only, and nothing automerges.
  - Toolchain, tool, pixi, hook and Python-floor bumps wait for dashboard approval.
  - Custom managers cover:
    - the toolchain channel and `rust-version`;
    - `tools.txt` and `tools-source.txt`;
    - nextest's `nextest-version`;
    - the biscuit-games-tooling tag;
    - `requires-pixi` and setup-pixi's `pixi-version`;
    - the hook revisions in both prek configs;
    - lychee's revision and its `LYCHEE_VERSION` arguments;
    - the `python_floor` in the Justfile.
  - The maturin and uv pins are pixi dependencies, so Renovate's native pixi manager reads them.
  - The release-workflow managers (setup-uv, maturin-version, twine) arrive with ticket 13.
- **New recipes:**
  - `site` builds the Pages content.
  - `fuzz-replay <target> <input>` replays a downloaded failing input.
- **Docs:** `docs/operations/maintenance.md` (workflows and triage) and `docs/how-to/maintain-dependencies.md` (the bot).

### Evidence

- **Dispatch.** Every dispatch was authorised.
  - `gh workflow run audit.yml --ref complete-bootstrap`: run 43010765549, `workflow_dispatch success`. The pull-request run 43010760214 also succeeded.
  - `fuzz.yml`, `mutants.yml` and `pages.yml` are **not runnable pre-merge**. Each returned `HTTP 404: workflow … not found on the default branch`, because dispatch needs the file on `main`.
- **Local equivalents of those three workflows' commands:**
  - `just fuzz smoke 30` printed `Done 112281910 runs in 31 second(s)`.
  - `just mutants` printed `4 mutants tested in 6s: 4 caught`.
  - `just site` produced `target/doc/index.html`.
  - `just fuzz-replay smoke <file>` printed `Executed … in 0 ms`.
- **Renovate managers.** Every custom manager's regex was run in Python against the real files, and each pin above matched with its current value. The new lychee manager matches `0.24.2` at the revision line and at both `LYCHEE_VERSION` arguments, and the generic hook-revision manager does not match lychee.
  - The Renovate config validator was **not run**: running it with `npx` was denied in this session.
- **CI.** Run 43010760092 on `720a534` was green.
- **Gate.** `just check` printed `All checks passed and the worktree is unchanged.`

### Adversarial review (Codex `gpt-6-astra`, triage by a separate Claude Sonnet subagent)

**Moment** (end), round 1. The reviewers were asked three questions. Their answers:

- **Broader permissions than needed:** none reported.
- **A pin the bot cannot see:** lychee (breakage 1) and the exact tooling Python (conformance 1).
- **A job that would fail silently:** none reported. The failure modes found were documentation that could not be executed (findings 2 and 3).

Findings:

1. **Conformance 1.** The pixi `python` pin was disabled, so `==3.14.10` would never move. **Valid.** It is now restricted to `/^3\.14\./`; 3.15 stays a decision.
2. **Conformance 2 and breakage 2** (the same finding). The advisory remediation named `just lock`, which keeps locked versions. **Valid.** The docs now name `just lock-upgrade`, then a review of the lockfile diff.
3. **Conformance 3 and breakage 3** (the same finding). The fuzz-crash procedure could not replay the downloaded input. **Valid.** The fix adds the `fuzz-replay` recipe, a row in the commands reference, and an update to `maintenance.md`.
4. **Breakage 1.** Lychee's revision and its `LYCHEE_VERSION` arguments were invisible to Renovate. **Valid.** A regex manager now covers them, with a grouped, dashboard-approved rule.

The fixes are small and mechanical, and were verified with `just check`, so no second round was run.

### Open points

- **Lychee manager.** Renovate's replacement of the lychee revision, which carries both a digest and a `lychee-v` tag comment, has not been seen working in a real Renovate run. Check the first dashboard pull request for it.
- **Unproven workflows.** `fuzz.yml`, `mutants.yml` and `pages.yml` are proven only by their local recipe equivalents and actionlint until they are on `main`.

### Maintainer steps

- **Install the Renovate GitHub app** on the repository.
- **After merging to `main`,** dispatch each workflow once:
  - `gh workflow run fuzz.yml --ref main`
  - `gh workflow run mutants.yml --ref main`
  - `gh workflow run pages.yml --ref main`
- **Pages.** When the repository becomes public, set the Pages source to "GitHub Actions". Until then the deploy job is skipped by design.
