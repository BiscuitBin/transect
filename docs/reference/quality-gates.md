---
title: "Quality gates"
kind: "reference"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["quality_gate_reference"]
requires: []
---

# Quality gates

`just check` runs the recipes listed under `[tool.biscuit-games-tooling] recipes` in
`pyproject.toml`, in this order, snapshotting the worktree before the first and
comparing after each, then runs `check-clean`. A recipe that fails, or that changes the
worktree, stops the run. On success it prints
`All checks passed and the worktree is unchanged.`

| # | Gate | What it proves | CI job |
| --- | --- | --- | --- |
| 1 | `check-toolchain` | cargo is rustup's proxy for the pinned release. | `rust`, both platforms |
| 2 | `lock-check` | `Cargo.lock`, `fuzz/Cargo.lock` and `pixi.lock` match their manifests. | `rust`, both platforms |
| 3 | `lint` | Every hook in `.pre-commit-config.yaml` passes over every file. | `documents` |
| 4 | `fmt-check` | Rust is formatted. | `rust`, Linux |
| 5 | `toml-check` | TOML is formatted and valid. | `rust`, Linux |
| 6 | `clippy` | The lint policy of [decision 0004](../decisions/0004-lint-policy-enforces-never-raise.md) holds, with no inner `#![allow`. | `rust`, Linux |
| 7 | `fuzz-build` | The fuzz crate builds under cargo-fuzz. | `rust`, Linux |
| 8 | `metrics` | Complexity, cohesion and coupling stay within `rustqual.toml`. | `rust`, Linux |
| 9 | `features` | Every feature combination compiles and passes clippy. | `rust`, Linux |
| 10 | `test-doc` | The doctests pass. | `rust`, both platforms (through `test`) |
| 11 | `coverage` | The Rust tests pass and cover at least 90% of lines. | `coverage` |
| 12 | `doc` | The API reference builds with no warning. | `rust`, Linux |
| 13 | `deny` | The dependency policy of [decision 0005](../decisions/0005-dependency-policy.md) holds. | `deny` |
| 14 | `deps-unused` | No dependency is unused. | `rust`, Linux |
| 15 | `py-lint` | ruff passes, and its positive control fails. | `python`, both platforms |
| 16 | `py-typecheck` | mypy strict passes, and its positive control fails. | `python`, both platforms |
| 17 | `py-test` | The Python tests pass against a develop build. | `python`, both platforms |
| 18 | `py-stubtest` | The stub matches the built module. | `python`, both platforms |
| 19 | `wheel-smoke` | Exactly one `cp311-abi3` wheel installs offline and imports. | `python`, both platforms |
| 20 | `wheel-smoke-floor` | The same wheel works on CPython 3.11. | `python` and `wheel-smoke-py311`, both platforms |
| 21 | `version-check` | One version everywhere ([decision 0006](../decisions/0006-single-version.md)). | `python`, both platforms |
| 22 | `check-docs` | The documents lint clean and the handbook contract holds. | `documents` |
| 23 | `check-undecided` | The `UNDECIDED` markers and the register agree. | `documents` |
| 24 | `snapshots-check` | Snapshots match and none is orphaned. | `rust`, Linux |

The `check` job also runs `just check` whole on both platforms. Every CI job that runs
recipes ends with `just check-clean`.

## Related pages

- [Commands](commands.md)
- [Decision 0004: The lint policy](../decisions/0004-lint-policy-enforces-never-raise.md)
