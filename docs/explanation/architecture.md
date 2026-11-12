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

## Related pages

- [Repository map](../project/repository-map.md)
- [Glossary](../project/glossary.md)
