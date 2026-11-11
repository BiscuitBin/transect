---
title: "Architecture"
kind: "explanation"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["architecture_overview"]
requires: []
---

# Architecture

The client is three crates in one direction
([decision 0003](../decisions/0003-crate-layering.md)):

```text
transectpy  (PyO3 binding; the transectpy wheel)
    |
transect    (Rust client API)
    |
libtransect (core)
```

## What exists

Each crate exposes its version and nothing else. `libtransect::version()` reads the
workspace version, `transect::version()` returns the core's, and the binding adds it to
the native module as `__version__`, which the Python package re-exports. That chain is
the whole of the client today, and it already exercises every layer: a Rust host and a
Python host see the same value from the same core.

## Where the future parts live

The core holds four private, documentation-only modules that mark where the client's
parts will be built:

| Module | Status |
| --- | --- |
| `ingest_queue` | `UNDECIDED` |
| `local_database` | `UNDECIDED` |
| `schema_evolution` | `UNDECIDED` |
| `data_writer` | `NOT YET IMPLEMENTED`: its role, a background thread draining the ingest queue into local databases, is settled; it waits on the three above. |

None of them has a type, trait or function: the shape of each waits on an entry on the
[open-decisions register](../project/open-decisions.md). Both shaping rules
([decision 0001](../decisions/0001-never-raise-never-block.md) and
[decision 0002](../decisions/0002-fork-safety.md)) bind every design that fills them.

## Related pages

- [Repository map](../project/repository-map.md)
- [Glossary](../project/glossary.md)
