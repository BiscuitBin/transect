---
title: "Commands"
kind: "reference"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["command_reference"]
requires: []
---

# Commands

The Justfile is the only interface: every command below is `just <recipe>`, and
`just` alone (or `just list`) prints them. Recipes marked **network** reach the network;
every other recipe runs offline once `just initialize` has run.

## Setup

| Recipe | What it does |
| --- | --- |
| `initialize` | The first-run command: pixi environment, toolchain, tools, lockfile sync and, in the primary checkout, hooks. **Network.** |
| `install-toolchain` | Installs the toolchain `rust-toolchain.toml` pins. **Network.** |
| `check-toolchain` | Refuses a cargo that is not rustup's proxy for the pin, an override that outranks the pin file, and a set `RUSTC`. |
| `install-tools` | Installs `tools.txt` and `tools-source.txt` into `.tools/bin`, and the Python floor interpreter into `.tools/python`. **Network.** |
| `install-hooks` | Installs the commit hook and prepares every hook environment; refuses in a secondary worktree. **Network.** |
| `sync` | Fetches and installs exactly what the three lockfiles say. **Network.** |
| `lock` | Updates the lockfiles within the manifests' constraints. **Network.** |
| `lock-upgrade` | Moves transitive dependencies within the manifests' constraints. **Network.** |
| `lock-check` | Proves every lockfile matches its manifest, offline. |

## Develop

| Recipe | What it does |
| --- | --- |
| `build` | Builds the workspace. |
| `test` | Runs the Rust tests under nextest, then the doctests. |
| `test-doc` | Runs the doctests. |
| `format` | Formats Rust (workspace and fuzz crate) and TOML. |
| `fix` | Runs every fixer in `.pre-commit-fix.yaml`, then clippy's fixes, then `lint`. |
| `py-develop` | Builds the extension in place into the pixi environment. |
| `bench` | Runs the benchmarks; never a gate. |
| `fuzz [target] [seconds]` | Fuzzes a target for a bounded time; never a gate. |
| `mutants` | Mutation testing over `libtransect` and `transect`; a report, never a gate. |
| `snapshots-review` | Reviews pending snapshots interactively. |
| `snapshots-accept` | Accepts snapshot changes without a terminal. |
| `wheel` | Builds the release wheel for this platform into `dist/`. |

## Gates

Each of these is described on [Quality gates](quality-gates.md).

| Recipe | What it does |
| --- | --- |
| `check` | Runs every gate in order and proves the worktree is unchanged. |
| `check-clean` | Proves the worktree matches a baseline, or is clean. |
| `lint` | Every hook in the gate configuration over every file. |
| `fmt-check` | rustfmt check, workspace and fuzz crate. |
| `toml-check` | taplo format check and lint. |
| `clippy` | Rejects inner `#![allow`, then clippy with warnings denied, workspace and fuzz crate. |
| `fuzz-build` | Builds the fuzz crate the way cargo-fuzz does. |
| `metrics` | rustqual over each crate. |
| `features` | Every feature combination compiles and passes clippy. |
| `coverage` | Line coverage of the Rust tests, with the 90% floor. |
| `doc` | The API reference with every rustdoc warning denied. |
| `deny` | Licences, bans and sources, for the workspace and the fuzz crate. |
| `deps-unused` | Unused dependencies, workspace and fuzz crate. |
| `py-lint` | ruff check and format check, with its positive control. |
| `py-typecheck` | mypy strict, with its positive control. |
| `py-test` | pytest over the binding and the scripts. |
| `py-stubtest` | The stub against the built module. |
| `wheel-smoke` | Installs the wheel offline into a fresh venv and imports it. |
| `wheel-smoke-floor` | The same on the Python 3.11 floor interpreter. |
| `version-check` | One version everywhere. |
| `check-docs` | Markdown lint, typos, the offline link check and the handbook validator. |
| `check-undecided` | The `UNDECIDED` markers and the register agree. |
| `snapshots-check` | Snapshots match and none is orphaned. |

## Outside the gate

| Recipe | What it does |
| --- | --- |
| `audit` | Security advisories, workspace and fuzz crate. **Network.** |
| `check-links-online` | Every link, external ones included. **Network.** |

## Related pages

- [Quality gates](quality-gates.md)
- [Develop locally](../how-to/develop-locally.md)
