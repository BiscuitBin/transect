---
title: "Maintain dependencies"
kind: "how-to"
audience: ["maintainer", "agent"]
canonical_for: ["dependency_updates"]
requires: []
---

# Maintain dependencies

Renovate proposes every version bump in this repository; nothing merges automatically.
`renovate.json` holds its configuration, which follows alliumpy's.

## What it tracks, and how

| Pin | Where | Arrives |
| --- | --- | --- |
| Crates | `Cargo.lock`, `fuzz/Cargo.lock`, ranges in the manifests | Grouped, one pull request, opened without approval once a release is seven days old; lockfile-only within the caret ranges. |
| GitHub Actions | SHA and version comment in every workflow and the setup action | Grouped, opened without approval after seven days. |
| Rust toolchain | `rust-toolchain.toml` channel, `rust-version` in both manifests | Held for dashboard approval: a toolchain moves the lint set. |
| pixi tools | `pyproject.toml` exact pins (including maturin and uv) | Held for dashboard approval; the app relocks `pixi.lock`. |
| cargo-nextest | `pyproject.toml` and `.config/nextest.toml` together | Held for dashboard approval. |
| Tool lists | `tools.txt`, `tools-source.txt` | Held for dashboard approval. |
| Python floor | `python_floor` in the `Justfile`, 3.11 only | Held for dashboard approval. |
| biscuit-games-tooling | its tag in `pyproject.toml` | Held for dashboard approval. |
| pixi itself | `requires-pixi` and the setup action's `pixi-version` together | Held for dashboard approval. |
| Hook revisions | both prek configurations | Held for dashboard approval. |
| Lockfile maintenance | all three lockfiles | Held for dashboard approval. |

The `setup-python` floor input moves by hand; the tooling interpreter moves only within
3.14, and lychee's revision and its two `LYCHEE_VERSION` arguments move together. A vulnerability fix skips the approval hold.

## Taking an update

1. Approve it on the dependency dashboard issue if it is held.
2. Check out the pull request and run `just check`.
3. Read the lockfile diff. A new transitive dependency is a dependency added: it needs
   the review [decision 0005](../decisions/0005-dependency-policy.md) asks for.
4. Merge one release at a time.

## Related pages

- [Decision 0005: Dependency policy](../decisions/0005-dependency-policy.md)
- [Scheduled maintenance](../operations/maintenance.md)
