---
name: python-change
description: Implement or review a change to the Python package, its stub, its tests or the repository scripts with the stubtest, pytest and wheel-smoke evidence the invariants require.
---

# Change the Python surface

1. Read `AGENTS.md` and `crates/transectpy/python/transectpy/_transectpy.pyi` first. The
   stub is the canonical description of the Python API; what it does not describe does
   not exist to a user of the extension.
2. Decide where the change lands: behaviour belongs in the core (`rust-change`); what
   Python sees is added in `crates/transectpy/src/lib.rs` and re-exported from
   `__init__.py`. No call may raise into the host (decision 0001).
3. For an exposed API change, change the three artefacts together: the stub, the Rust
   binding and the pytest case under `crates/transectpy/tests/`. Write the pytest case
   first and watch it fail against a rebuilt extension.
4. Behaviour must hold in a forked child too (decision 0002): add the case to
   `test_fork.py` through `run_in_fork` and `run_in_fork_pool`, starting from the marked
   `# FORK-SAFETY PLACEHOLDER`.
5. Repository scripts under `scripts/` are tested under `tests/scripts/`, test-first.
6. Run `just py-lint`, `just py-typecheck`, `just py-test`, `just py-stubtest`,
   `just wheel-smoke`, `just wheel-smoke-floor` and `just version-check`, in that order,
   then `just check`. A stubtest failure is a disagreement to resolve, never an allowlist
   entry without a reason beside it. `just py-test` rebuilds the extension first.
7. Report by `file:line`: what changed in the stub, binding and test.
