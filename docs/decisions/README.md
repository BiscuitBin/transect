---
title: "Architecture decisions"
kind: "decision"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["decision_index"]
requires: []
---

# Architecture decisions

A record of what was chosen, what it cost, and what would have to change for the choice
to be revisited. Each entry is numbered and never renumbered; a decision that is
superseded is marked rather than deleted, because the reasoning is what makes the
successor legible. What is not yet decided is not here: it is on the
[open-decisions register](../project/open-decisions.md), and it moves here only when a
decision is made.

## The record

| Number | Decision |
| --- | --- |
| [0003](0003-crate-layering.md) | Three crates, one dependency direction |
| [0004](0004-lint-policy.md) | The lint policy rejects panic paths |
| [0005](0005-dependency-policy.md) | Dependency policy: caret ranges, lockfiles and cargo-deny |
| [0006](0006-single-version.md) | One version for every crate and the wheel |
| [0007](0007-supported-platforms.md) | Linux and macOS are the supported platforms |
| [0008](0008-tool-manager.md) | pixi, rustup and just as the tool manager |
| [0009](0009-hooks.md) | A read-only hook gate and a separate fixer |
| [0010](0010-release-process.md) | One tag releases to PyPI and crates.io, each behind its own approval |

## Writing a new one

Copy the shape of an existing entry: context, the decision, the consequences including
the ones that hurt, and what would reopen it. Add the file, add a manifest entry, add a
row above. A decision that answers an entry on the register removes that entry in the
same change.

## Related pages

- [Documentation map](../README.md)
- [Open decisions](../project/open-decisions.md)
