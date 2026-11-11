# 08: Fork test harness stub

**What to build:** The Python test suite has a working harness for the fork-safety rule, so that when the client gains behaviour, a test of that behaviour under a forked worker is a few lines rather than new infrastructure. The harness imports `transectpy` in a parent process, forks a child, has the child use the package and report a result back, and has the parent assert on it, with a timeout so a hung child fails the test instead of hanging the suite. Today the only thing a child can check is the import and the version; the place for real assertions is clearly marked as a placeholder.

The fork must be requested explicitly. The development environment's Python no longer forks by default on either supported platform, so a harness that relies on the default start method would test nothing.

**Adversarial review:** Key moments: at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: whether the child is provably forked on both operating systems; how the harness behaves when the child hangs, crashes or is killed; whether it can pass without the child running the callable; whether it would survive a background thread existing in the parent.

**Blocked by:** 04

**Status:** ready-for-agent

- [x] A reusable test helper runs a callable in an explicitly forked child and returns its result or failure to the parent
- [x] The helper covers both a raw process fork and a forked worker pool, the shape gunicorn-style servers use
- [x] A child that hangs, crashes or exits non-zero fails the test within a bounded time and is reaped
- [x] A test proves the child really was forked (it sees parent state set after import) rather than freshly started
- [x] A test asserts that the package imported before the fork is usable in the child and reports the same version
- [x] The placeholder for future fork-safety assertions is marked and referenced from the open-decisions page
- [x] The tests pass on Linux and macOS in CI and satisfy the strict lint and type gates
- [x] No fork-handling behaviour is added to the client itself
- [x] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model

## Hand-back

Commits: `f946908` (the ticket) and the commit carrying this hand-back (review fixes). Both are on `complete-bootstrap`, draft PR #2.

### What was built

- **`crates/transectpy/tests/forking.py`**, written test-first in five red→green slices, then two more slices from the review.
  - `run_in_fork(fn, timeout)` takes an explicit `os.fork`. The child runs `fn` and sends `("ok", value)` or `("error", traceback)` over a pipe, then always calls `os._exit`. One deadline covers both reading the result and the child's exit: past it, the child is SIGKILLed and reaped, and the helper raises `ForkTimeoutError`. A signal, a non-zero exit, an empty pipe or an exception in the child raises `ForkFailedError`.
  - `run_in_fork_pool(fn, timeout)` uses `multiprocessing.get_context("fork").Pool(1)`, the shape gunicorn-style servers use. On a timeout it SIGKILLs the busy worker and then terminates and joins the pool. Workers are found through the public `multiprocessing.active_children()`.
  - Python 3.12+'s "multi-threaded, use of fork()" `DeprecationWarning` is silenced by message and category only, around the helpers' own forks.
- **`test_forking.py`** has 11 tests covering:
  - the callable really runs: a nonce made in the parent comes back, from another pid;
  - a hang, a crash by signal, a non-zero exit and an exception each fail within `BOUND_SECONDS`, and the child is reaped;
  - a pool worker that runs, hangs, crashes or ignores SIGTERM;
  - a child that closes its pipe and then hangs;
  - a background thread alive in the parent.
- **`test_fork.py`**:
  - the child sees a sentinel the parent set after importing `transectpy`, in both a raw fork and a pool, which proves it was forked rather than started fresh;
  - the version imported before the fork is the child's version;
  - `# FORK-SAFETY PLACEHOLDER`, a test that today asserts only the version. It is referenced from the open-decisions register.
- **Docs.**
  - `mypy_path` gains `crates/transectpy/tests`.
  - Decision 0002 now describes the harness.
  - The register lists the placeholder under "Open points".
  - The repository map names the files.
- **No fork handling was added to the client.**

### Evidence

- **Really forked.** With the pool switched to `get_context("spawn")`, `test_the_child_is_forked_not_started_fresh` fails: `AssertionError: assert 'initial' == 'set by 83285 after import'` (`ai_tmp/evidence/08/spawn-control.txt`).
- **The review's holes, red then green.**
  - Before the fix, the two new tests hung the run until the outer `timeout` killed it: a pool worker ignoring SIGTERM, and a child hanging after closing its pipe.
  - After it, all 19 tests in `crates/transectpy/tests` pass, three runs out of three, in about 6 s.
- **Both platforms.** CI run 43003880534 (`f946908`) passed `py-test` on ubuntu and macOS (`27 passed`), and every other job.
- **Checks.** `just check` ends `All checks passed and the worktree is unchanged.` Ruff and mypy strict at 3.11 are clean.

### Adversarial review (Codex `gpt-6-astra`, triage by a separate Claude Sonnet subagent)

End of ticket, round 1. Both lenses reported the same two findings:

1. **Pool cleanup hangs on a worker that ignores SIGTERM**, because `terminate()` and `join()` have no deadline. **Valid**, high. Fixed: on the timeout path only, the busy worker gets SIGKILL before `terminate()`. Triage observed that killing an idle worker on the success path deadlocks `terminate()` on the pool's queue lock, so that path is untouched.
2. **The raw fork's deadline stops at pipe EOF, then `waitpid` blocks.** **Valid**, high. Fixed: the deadline also covers the child's exit, through `waitpid(WNOHANG)` polling, with kill-and-reap on expiry.

Each fix has a regression test.

### Open points

- **Replacement workers.** A pool worker that the pool replaced after a crash is not in the SIGKILL list. It is idle by construction, so `terminate()` ends it.
- **macOS.** The CPython `fork` start method has known caveats when Apple frameworks are loaded; this harness loads none.

### Maintainer steps

None for this ticket.
