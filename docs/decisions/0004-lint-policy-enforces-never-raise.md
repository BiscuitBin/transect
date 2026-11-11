---
title: "Decision 0004: The lint policy is the enforcement of never-raise"
kind: "decision"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["decision_lint_policy"]
requires: []
---

# Decision 0004: The lint policy is the enforcement of never-raise

Adapted from the models' Rust quality gate (alliumpy decision 0005, pachinko's lint
tables), with additions.

## Context

[Decision 0001](0001-never-raise-never-block.md) forbids raising into the host, and a Rust
panic becomes an exception at the PyO3 boundary. Review alone does not reliably find
every panic path, so the panic paths that a tool can find are rejected by the tool.

## Decision

The root `Cargo.toml` declares the models' lint policy in `[workspace.lints]`: unsafe code
forbidden, the pedantic and cargo clippy groups, missing docs, exhaustive public types,
and the panic family. The two pure-Rust crates inherit it; the binding crate and the
fuzz crate carry verbatim copies, because a crate cannot both inherit and override.
Every level is `warn`, and `just clippy` passes `-D warnings`, so a local build never
breaks mid-edit and the gate never lets a warning through.

Outside test code, the gate rejects:

- `unwrap`, `expect`, `panic!`, `unreachable!`, `todo!` and `unimplemented!`;
- unchecked indexing and slicing (`indexing_slicing`, an addition to the models);
- integer `/` and `%` (`integer_division_remainder_used`, an addition): use
  `checked_div` and `checked_rem`;
- `assert!`, `assert_eq!`, `assert_ne!` and their `debug_` forms, through `clippy.toml`'s
  `disallowed-macros` (an addition); a test module lifts that ban with a reasoned
  `#[expect]`.

`clippy.toml` lifts unwrap, expect, panic and indexing in test code only. A lint is
silenced only by `#[expect(lint, reason = "...")]`: the lints reject an outer `#[allow]`
and any suppression without a reason, and `just clippy` itself rejects an inner
`#![allow`, which those lints cannot see. `just features` runs clippy over every feature
combination, so a panic behind a disabled feature is still found.

## Consequences

Error paths are explicit everywhere, at the cost of some verbosity. Test modules carry one
reasoned `#[expect(clippy::disallowed_macros)]`. Arithmetic overflow from `+`, `-`, `*`,
shifts and negation is not linted: it panics in debug builds and wraps in release, and
`clippy::arithmetic_side_effects` flags every `+`. That gap is on the
[register](../project/open-decisions.md) until the client has real arithmetic.

## What would reopen this

A clippy release that adds a test-scoped exemption for the assertion macros, which would
replace the `disallowed-macros` arrangement, or a fork-handling design that needs unsafe
code.

## Related pages

- [Quality gates](../reference/quality-gates.md)
- [Decision 0001: Never raise, never block](0001-never-raise-never-block.md)
