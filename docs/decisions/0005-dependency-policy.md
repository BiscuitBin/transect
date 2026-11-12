---
title: "Decision 0005: Dependency policy: caret ranges, lockfiles and cargo-deny"
kind: "decision"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["decision_dependency_policy"]
requires: []
---

# Decision 0005: Dependency policy: caret ranges, lockfiles and cargo-deny

Adapted from alliumpy decision 0004, which carries pachinko's decision 0007.

## Context

The crates are libraries: a manifest range is a constraint every future consumer inherits,
so exact pins in a library manifest only cause resolution conflicts. The gate snapshots
the worktree between recipes, so no recipe may rewrite a lockfile.

## Decision

Third-party Rust dependencies use full `x.y.z` caret ranges in the one
`[workspace.dependencies]` table, and members inherit them. `Cargo.lock` is committed and
is the pin; every cargo invocation that resolves dependencies passes `--locked`, with the
exceptions below, and `just lock-check` proves the lockfiles match their manifests,
offline.

The snapshot recipes cannot pass `--locked`, because cargo-insta hands trailing options
to nextest's test binaries; they depend on `just lock-check` and run offline
(`CARGO_NET_OFFLINE`). The fuzz recipes cannot pass it to cargo-fuzz either, and run an
offline `cargo update --locked` first. `libfuzzer-sys` is a caret range in
`fuzz/Cargo.toml`, not in the workspace table: the fuzz crate is excluded from the
workspace, never published, and cannot inherit the table, and its committed
`fuzz/Cargo.lock` is its pin. pixi's tools are exact pins in `pyproject.toml`, locked in `pixi.lock`;
tools pixi cannot supply are exact pins in `tools.txt` and `tools-source.txt`.

`deny.toml` holds the policy cargo-deny enforces, offline in `just deny` for both the
workspace and the fuzz crate: a permissive licence allow-list, crates.io as the only
source, no wildcard requirements and no `openssl-sys`. Yanked releases are denied under
`[advisories]`, which needs the RustSec database and so runs from `just audit`, outside
`just check`.
Dev-dependencies sit outside the checked graph. `just deps-unused` rejects a dependency
nothing uses. A new dependency needs a reason written beside its range in the manifest.

## Consequences

One resolution is tested, not every version a range permits. A lockfile move is a diff to
read. Adding a dependency is a reviewed change, never a side effect.

## What would reopen this

Publishing the crates may add a minimal-versions check, since a caret range claims the
crate builds against its floor.

## Related pages

- [Quality gates](../reference/quality-gates.md)
- [Decision 0008: Tool manager](0008-tool-manager.md)
