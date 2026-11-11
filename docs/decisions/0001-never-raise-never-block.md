---
title: "Decision 0001: The client never raises into or blocks the host application"
kind: "decision"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["decision_never_raise_never_block"]
requires: []
---

# Decision 0001: The client never raises into or blocks the host application

## Context

Transect's client runs inside someone else's program: the host application. The host
records data through the client because it wants that data, but the data is never the
host's purpose. A logging library or a metrics client is in the same position, and the
established practice for both is the same: a failure in the instrument must not become a
failure of the instrumented program, and recording must not make the program wait.

In this workspace the boundary to a Python host is PyO3, which turns a Rust panic that
reaches it into a Python exception. A panic anywhere in the client is therefore an
exception raised into the host.

## Decision

This is the first of the two shaping rules; [decision 0002](0002-fork-safety.md) is the
other. Two properties hold for every public entry point of the Rust client API and the
Python client, in every build profile:

1. **Never raise.** No call into the client raises an exception into the host (Python) or
   panics (Rust) because of anything the client does or anything that happens to the
   data after the call returns. Failures inside the client are the client's to handle.
2. **Never block.** No call into the client (recording, construction, configuration,
   flushing or shutdown) waits on storage, on the network, on a lock held while either
   is used, or on the data writer. Every such call returns after a bounded amount of the
   caller's own work.

The rule applies to the client's own failures. Whether a call that the host makes
incorrectly is reported to the host, and how, is not settled here; nor is what happens
to data the client cannot accept. Both are recorded on the
[open-decisions register](../project/open-decisions.md).

The Rust lint policy is the rule's enforcement in code: every panic shortcut is rejected
outside tests ([decision 0004](0004-lint-policy-enforces-never-raise.md)).

## Consequences

Every future API is reviewed against both properties before its first line is written,
and a design that can only meet them by waiting or raising is rejected. Test code may
panic freely; production code may not, so error paths are explicit. Data loss under
failure is possible by construction, and how much is acceptable is part of the open
decisions, not a defect of this rule.

## What would reopen this

A host class that wants the client to fail loudly, such as a batch job for which the
recorded data is the product. That would be a separate, explicitly chosen mode, never a
change of the default.

## Related pages

- [Decision 0002: Fork safety](0002-fork-safety.md)
- [Decision 0004: The lint policy](0004-lint-policy-enforces-never-raise.md)
- [Open decisions](../project/open-decisions.md)
