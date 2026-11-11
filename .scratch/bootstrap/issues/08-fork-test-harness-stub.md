# 08: Fork test harness stub

**What to build:** The Python test suite has a working harness for the fork-safety rule, so that when the client gains behaviour, a test of that behaviour under a forked worker is a few lines rather than new infrastructure. The harness imports `transectpy` in a parent process, forks a child, has the child use the package and report a result back, and has the parent assert on it, with a timeout so a hung child fails the test instead of hanging the suite. Today the only thing a child can check is the import and the version; the place for real assertions is clearly marked as a placeholder.

The fork must be requested explicitly. The development environment's Python no longer forks by default on either supported platform, so a harness that relies on the default start method would test nothing.

**Adversarial review:** Key moments: at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: whether the child is provably forked on both operating systems; how the harness behaves when the child hangs, crashes or is killed; whether it can pass without the child running the callable; whether it would survive a background thread existing in the parent.

**Blocked by:** 04

**Status:** ready-for-agent

- [ ] A reusable test helper runs a callable in an explicitly forked child and returns its result or failure to the parent
- [ ] The helper covers both a raw process fork and a forked worker pool, the shape gunicorn-style servers use
- [ ] A child that hangs, crashes or exits non-zero fails the test within a bounded time and is reaped
- [ ] A test proves the child really was forked (it sees parent state set after import) rather than freshly started
- [ ] A test asserts that the package imported before the fork is usable in the child and reports the same version
- [ ] The placeholder for future fork-safety assertions is marked and referenced from the open-decisions page
- [ ] The tests pass on Linux and macOS in CI and satisfy the strict lint and type gates
- [ ] No fork-handling behaviour is added to the client itself
- [ ] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model
