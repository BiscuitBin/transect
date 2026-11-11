# 11: Scheduled workflows, Pages and renovate

**What to build:** The repository looks after itself between changes: advisories, fuzzing and mutation testing run weekly and report without gating merges, the Rust API documentation is published as a site from main, and every pinned version in the repository is tracked by the dependency bot. All of this carries the models' workflows and bot configuration.

**Adversarial review:** Key moments: at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which workflow has broader permissions than it needs; which pin the dependency bot cannot see; which scheduled job would fail silently for months.

**Blocked by:** 10

**Status:** ready-for-agent

- [ ] An advisory workflow runs on pull requests, weekly and on demand, and is not a required check
- [ ] A fuzz workflow runs each fuzz target weekly and on demand for a bounded time and uploads failing inputs
- [ ] A mutation-testing workflow runs weekly and on demand and uploads its report
- [ ] A Pages workflow builds the API docs site from main and deploys it, with deployment guarded so it is skipped while the repository is private
- [ ] All workflows use SHA-pinned actions, read-only default permissions, the shared setup action, concurrency groups and timeouts, and pass the workflow lint
- [ ] The dependency bot configuration follows the models: grouped updates, lockfile-only ranges, no automerge, dashboard approval for tool and toolchain bumps
- [ ] Custom managers cover every pin the bot cannot see natively: the toolchain channel and minimum Rust version, the tool pin lists, the test-runner version, the shared tooling tag, the pixi version, hook revisions, and the maturin and uv pins
- [ ] Each workflow has been run once on demand and its result is quoted in the hand-back, or the hand-back states that authorisation to run it was not given
- [ ] The operations and how-to pages describe these workflows and the check command ends green
- [ ] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model
