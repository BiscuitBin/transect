---
title: "Decision 0006: One version for every crate and the wheel"
kind: "decision"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["decision_single_version"]
requires: []
---

# Decision 0006: One version for every crate and the wheel

## Context

The core, the Rust client and the Python binding change together: a Rust client release
without the matching core, or a wheel built from another core, would be a different
client under the same name. Separate versions would only describe that mistake.

## Decision

`[workspace.package] version` in the root `Cargo.toml` is the version. Every member crate
inherits it, and the core and the Rust client report it through their `version()`
functions; the wheel manifest `crates/transectpy/pyproject.toml` repeats it statically,
and the Python package reports it as `transectpy.__version__`. `just version-check`
fails when the workspace, any member crate, the wheel manifest, the installed wheel's
module or its metadata disagree. There is one changelog for the one version.

## Consequences

A change to any crate is a release of all of them. A packaging-only fix to the wheel is
still a new version for every crate.

## What would reopen this

A crate with an independent consumer and release rhythm, such as a core used by another
product.

## Related pages

- [Decision 0003: Crate layering](0003-crate-layering.md)
- [Quality gates](../reference/quality-gates.md)
