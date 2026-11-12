---
title: "Decision 0003: Three crates, one dependency direction"
kind: "decision"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["decision_crate_layering"]
requires: []
---

# Decision 0003: Three crates, one dependency direction

Adapted from pachinko's library-and-client shape and alliumpy's binding crate.

## Context

The client has two audiences today, Rust hosts and Python hosts, and both must behave
identically. The behaviour therefore lives once, in Rust, and each audience reaches it
through a thin layer of its own.

## Decision

The Cargo workspace holds three crates:

| Crate | Role | May depend on |
| --- | --- | --- |
| `libtransect` | The core: every behaviour of the client. | Third-party crates only. |
| `transect` | The Rust client API that Rust hosts use. | `libtransect`. |
| `transectpy` | The PyO3 binding, built by maturin into the `transectpy` wheel as the private module `transectpy._transectpy`. | `transect`. |

Dependencies point up the table and never down: the core knows nothing of its clients,
and the binding reaches the core only through the Rust client, so Rust and Python hosts
see the same API. PyO3 is a dependency of the binding crate alone. The fuzz crate under
`fuzz/` sits outside the workspace and depends on the core only.

## Consequences

Python-specific behaviour, if any is ever needed, lives in the binding and is a
translation of the Rust API, never a second implementation. The binding crate has no Rust
tests; its behaviour is tested from Python. Every crate shares one version
([decision 0006](0006-single-version.md)).

## What would reopen this

A third host language, which would add a sibling of `transectpy` rather than change the
direction.

## Related pages

- [Repository map](../project/repository-map.md)
- [Decision 0006: One version](0006-single-version.md)
