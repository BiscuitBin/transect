# 04: Python package and gate

**What to build:** A Python developer can build the client and run `import transectpy`, and get a typed, linted, tested package whose only content is its version. The Python package is named `transectpy` for both the distribution and the import name, following alliumpy's naming. A third crate, the PyO3 binding crate, also named `transectpy` (as alliumpy names its binding crate after its package), is added to the workspace as a native extension that depends on the Rust client crate; maturin builds it into a private extension module, `transectpy._transectpy`, inside the `transectpy` package, with a hand-written type stub as the canonical description of the Python API and a typed-package marker. Layout, build settings and gates follow alliumpy: stable-ABI wheels with a Python 3.11 floor, strict linting and type checking, pytest, stub-versus-module verification, and an offline installed-wheel smoke test.

The binding crate is the place where Rust meets the host application, so the never-raise lint policy must demonstrably apply to it even though it keeps its own copy of the lint tables. It has no Rust tests and is excluded from Rust test, coverage and mutation runs, as in alliumpy. The package exposes nothing but its version: no table, column or write API.

**Adversarial review:** Key moments: after the binding crate and package build and import, before the gates are wired; and at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: whether the lint policy truly applies to the binding crate; whether the wheel is really stable-ABI and really works on the Python floor; whether stub and module can drift undetected; whether any API beyond the version has leaked in.

**Blocked by:** 01

**Status:** ready-for-agent

- [x] The binding crate is named `transectpy`, is a workspace member built as a native extension, depends on the Rust client crate, shares the workspace version, and uses the stable ABI with a Python 3.11 floor
- [x] The wheel manifest uses maturin, names the distribution `transectpy`, places the extension as a private module inside the `transectpy` package, and builds from the locked dependency set
- [x] After a develop build, `import transectpy` succeeds and the package reports a version equal to the workspace version
- [x] A hand-written stub describes the extension module, a typed marker ships in the package, and stub verification against the built module passes
- [x] Linting (all rules, with the models' documented exceptions), format check and strict type checking pass over the package, its tests and repository scripts
- [x] Positive-control fixtures prove the linter and the type checker fail when they should
- [x] A deliberate unwrap or panic in non-test code of the binding crate makes the clippy recipe fail; evidence quoted in the hand-back, violation not committed
- [x] Pytest runs against the develop build and asserts the import and version
- [x] A wheel recipe builds exactly one wheel; a smoke recipe installs it offline into a fresh environment and imports it in isolated mode
- [x] The smoke also passes on a plain Python 3.11 interpreter, proving the floor
- [x] Rust test, coverage and mutation recipes exclude the binding crate; the dependency policy, feature and docs recipes still cover it
- [x] The Python gates are in the ordered check list and the check command ends green
- [x] CI has a `python` job running the Python gates on Linux and macOS, plus the Python 3.11 floor smoke
- [x] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model

## Hand-back

Commits: `b115056` (the ticket) and the commit carrying this hand-back (the review fix). Both are on `complete-bootstrap`, draft PR #2.

### What was built

- **Binding crate `crates/transectpy`.**
  - A cdylib and workspace member that shares the workspace version and is `publish = false`.
  - It depends on `transect` only, never on the core. `pyo3 0.30.1` with `abi3-py311` is a workspace dependency used by this crate alone.
  - Its `[lints]` tables are the root `[workspace.lints]` copied verbatim.
  - `src/lib.rs` is a `#[pymodule] _transectpy` that adds one attribute: `__version__ = transect::version()`.
- **Python package.**
  - The maturin manifest names the distribution `transectpy`, with `module-name = "transectpy._transectpy"`, `python-source = "python"`, `locked = true`, a static version 0.1.0 and `requires-python >=3.11`. The licence is copied into the crate directory for `license-files`.
  - The package itself is `__init__.py` (re-exporting `__version__`), the hand-written stub `_transectpy.pyi`, and `py.typed`.
- **Tests and checks.**
  - `tests/test_version.py`: import, version equal to the workspace version (read from `Cargo.toml` independently), the version comes from the native module, the stub type matches, distribution metadata agrees, and nothing but the version is public.
  - `scripts/version_check.py`, written test-first (five red→green slices in `tests/scripts/test_version_check.py`, run against a miniature repository with real `cargo metadata`). It compares the workspace, every member crate, the wheel manifest, and the installed wheel's module and metadata versions.
  - `ruff.toml` and `mypy.ini` follow alliumpy: ruff with `select = ALL`, and mypy strict with `python_version = 3.11`.
  - Fixtures: `tests/fixtures/py-lint-violation/{ruff,mypy}.py` and `tests/fixtures/smoke/smoke.py`.
- **Recipes.** `py-develop`, `py-lint`, `py-typecheck`, `py-test`, `py-stubtest`, `wheel`, `wheel-smoke`, `wheel-smoke-floor` and `version-check`.
  - `wheel-smoke` refuses anything but exactly one `cp311-abi3` wheel.
  - `wheel-smoke-floor` installs that wheel offline on uv's CPython 3.11.18, which `install-tools` places in `.tools/python`. The pin is `python_floor` in the Justfile.
  - `PYO3_PYTHON` is exported to pixi's Python.
- **Exclusions.**
  - `test`, `test-doc`, `coverage` and `snapshots-*` take `--exclude transectpy`. `mutants` already names the two pure crates.
  - `clippy`, `features`, `doc`, `deny` and `deps-unused` still cover the binding crate, and `metrics` now runs rustqual on it too.
- **Pins.** maturin 1.16.0, uv 0.13.7, pytest 9.1.1, ruff 0.17.2, mypy 2.4.0 and pyo3 0.30.1, all verified on 2026-11-11.
- **Check list.** It is in alliumpy's order: … deny, deps-unused, py-lint, py-typecheck, py-test, py-stubtest, wheel-smoke, wheel-smoke-floor, version-check, snapshots-check.
- **CI.**
  - A `python` job runs on ubuntu and macOS and uploads each platform's wheel.
  - A `wheel-smoke-py311` job runs on both platforms on `setup-python` 3.11, with no pixi and no `just`.
  - The setup action's `.tools` cache key now includes the Justfile, which holds the floor pin.

### Evidence

Everything below is under `ai_tmp/evidence/04/`. Every violation was reverted.

- **The lint policy applies to the binding** (`clippy-binding-controls.txt`). `Some(..).unwrap()` in `_transectpy` fails `just clippy` with exit 101, `used unwrap() on an Option value --> crates/transectpy/src/lib.rs:11:31`. `panic!("x")` fails with exit 101, `panic should not be present in production code`.
- **Import.** `just py-develop`, then `python -I -c 'import transectpy'`, reports `0.1.0`. The extension is `_transectpy.abi3.so`, and the public names are only `__version__`.
- **Stable ABI and the floor.**
  - Locally the wheel is `transectpy-0.1.0-cp311-abi3-macosx_11_0_arm64.whl`.
  - The `wheel-smoke-floor` venv is `lib/python3.11` and asserts `sys.version_info[:3] == (3, 11, 18)`.
  - In CI, run 42996986211 installed `…-cp311-abi3-manylinux_2_34_x86_64.whl` and `…-cp311-abi3-macosx_11_0_arm64.whl` on `setup-python` 3.11, and both printed `transectpy 0.1.0 imported from …/python3.11/site-packages/…`.
- **Stub drift is caught** (`python-positive-controls.txt`, `stub-version-type-control.txt`):
  - the module gains `extra`: `just py-stubtest` exits 1 with `__all__ names exported from the stub do not correspond`;
  - the stub declares `ghost`: same, exit 1;
  - the stub types `__version__` as `Literal["9.9.9"]`: `just py-typecheck` exits 1 with `Expression is of type "Literal['9.9.9']", not "str" [assert-type]`.
- **Version drift.** With the wheel manifest at 0.1.1, `just version-check` exits 1: `wheel manifest crates/transectpy/pyproject.toml says 0.1.1, the workspace version is 0.1.0`.
- **Lint and type controls.**
  - An unused import in the package fails `just py-lint` (F401).
  - `VALUE: int = "a"` in the package fails `just py-typecheck` (`[assignment]`).
  - The fixture controls run inside every `py-lint` and `py-typecheck`.
- **Checks.**
  - `py-test` passes 9 tests: 4 binding tests (5 after the fix) and 5 script tests.
  - `just check` ends `All checks passed and the worktree is unchanged.`
  - CI run 42996986211 (`b115056`) was green on every job, ubuntu and macOS alike: `check`, `rust`, `python`, `wheel-smoke-py311`, `coverage` and `deny`.

### Adversarial review (Codex `gpt-6-astra`, triage by a separate Claude Sonnet subagent)

**Moment 1** (the binding builds and imports, before the gates). Both lenses reported no findings.

**Moment 2** (end), round 1. Conformance reported no findings.

1. **`stubtest` ignores `__version__`** (mypy's `IGNORED_MODULE_DUNDERS`), so the stub's only declaration could drift (breakage). **Valid.** Fixed with an `assert_type(native.__version__, str)` test, which mypy checks through `py-typecheck`, plus a runtime `isinstance` check and a control.

### Open points

- **Local Linux wheels are not release-grade.** A Linux wheel built by `just wheel` on the CI runner is tagged `manylinux_2_34`, the runner's glibc. Release wheels need maturin-action's manylinux and musllinux containers (ticket 13).
- **The floor interpreter is a download.** uv's python-build-standalone 3.11.18, fetched by `install-tools`, is the one first-run download not covered by a lockfile or `tools*.txt`. Ticket 11's renovate config must track the `python_floor` pin.

### Maintainer steps

None for this ticket.
