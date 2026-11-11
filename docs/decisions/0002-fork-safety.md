---
title: "Decision 0002: Correct behaviour under fork is a requirement"
kind: "decision"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["decision_fork_safety"]
requires: []
---

# Decision 0002: Correct behaviour under fork is a requirement

## Context

Python web servers such as gunicorn import the application once in a parent process and
then fork a pool of worker processes from it. A forked child inherits a copy of the
parent's memory but only the thread that called `fork`: any background thread the parent
started does not exist in the child, and any lock that thread held stays held forever.
The client's settled shape includes exactly such a background thread, the data writer,
so a client that ignored forking would silently stop writing in every worker, or hang.

## Decision

This is the second of the two shaping rules; [decision 0001](0001-never-raise-never-block.md)
is the first. A host that imports the client and then forks, by a raw process fork or a
forked worker pool, gets in each child a client that obeys decision 0001 and records data
as it would in an unforked process. Both rules hold in the parent too.

The mechanism is deliberately left open: which hooks, checks or re-initialisation achieve
it depends on the undecided ingest queue and local database. Whether it will need unsafe
code, which [decision 0004](0004-lint-policy-enforces-never-raise.md) forbids today, is an
open point on the [register](../project/open-decisions.md).

The Python test suite carries a harness, `crates/transectpy/tests/forking.py`, that runs
a callable in an explicitly forked child, by a raw `os.fork` or in a forked worker pool,
and fails within a bounded time if the child hangs, crashes or exits non-zero. Its tests
prove the child is forked rather than started fresh. Until the client has behaviour, the
child can check only the import and the version; the marked placeholder for real
assertions is listed on the register.

## Consequences

Every design for the ingest queue, the local database and the data writer must say how it
behaves across a fork before it is accepted. Tests of client behaviour are expected to run
under a forked worker as well as in a plain process.

## What would reopen this

Nothing short of dropping forked servers as hosts, which would remove the most common
Python deployment.

## Related pages

- [Decision 0001: Never raise, never block](0001-never-raise-never-block.md)
- [Open decisions](../project/open-decisions.md)
