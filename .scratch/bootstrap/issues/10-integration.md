# 10: Integration: one `just check`, one required CI check

**What to build:** After the parallel lanes have merged, one local command and one CI status tell the whole truth about the repository. The ordered check list contains every gate from tickets 02 to 09 in a deliberate order (cheap and offline first), the command ends with the success line on a clean worktree, and CI aggregates every job behind a single job that is the only required status check and fails if any job it needs failed, was cancelled or was skipped.

This is where conflicts in the files the lanes shared (the Justfile, the check list, the hook configurations, the workflow, ignore rules) are resolved and where gaps between lanes are found.

**Adversarial review:** Key moments: after the lanes are merged and the full check first runs green; and at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: which gate from tickets 02 to 09 is missing from the check list or from CI; which job can be skipped while the aggregate stays green; what differs between a fresh clone and the author's worktree; what the lanes each assumed the other would do.

**Blocked by:** 02, 03, 04, 05, 06, 07, 08, 09

**Status:** ready-for-agent

- [ ] The ordered check list holds every gate once, in the models' order with the Python gates placed as in alliumpy
- [ ] From a fresh clone, initialize then check ends with the success line and an empty worktree status, on Linux and on macOS
- [ ] Every gate in the list also runs in some CI job, and each CI job ends by proving the worktree is clean
- [ ] A single aggregate job needs every other job and is green only when all succeeded
- [ ] The reference pages for commands and quality gates match the actual recipes and list
- [ ] The repository map, agent file project map and skills name only things that exist
- [ ] Nothing in the Rust client or the Python package beyond the version item has appeared, and the open-decisions register still matches the stubs
- [ ] Any gate found to pass vacuously is given a positive control or reported in the hand-back
- [ ] Repository settings that need a maintainer (marking the aggregate job as required, branch protection) are listed in the hand-back, not changed
- [ ] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model
