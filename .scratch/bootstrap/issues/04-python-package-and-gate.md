# 04: Python package and gate

**What to build:** A Python developer can build the client and run `import transectpy`, and get a typed, linted, tested package whose only content is its version. The Python package is named `transectpy` for both the distribution and the import name, following alliumpy's naming. A third crate, the PyO3 binding crate, also named `transectpy` (as alliumpy names its binding crate after its package), is added to the workspace as a native extension that depends on the Rust client crate; maturin builds it into a private extension module, `transectpy._transectpy`, inside the `transectpy` package, with a hand-written type stub as the canonical description of the Python API and a typed-package marker. Layout, build settings and gates follow alliumpy: stable-ABI wheels with a Python 3.11 floor, strict linting and type checking, pytest, stub-versus-module verification, and an offline installed-wheel smoke test.

The binding crate is the place where Rust meets the host application, so the never-raise lint policy must demonstrably apply to it even though it keeps its own copy of the lint tables. It has no Rust tests and is excluded from Rust test, coverage and mutation runs, as in alliumpy. The package exposes nothing but its version: no table, column or write API.

**Adversarial review:** Key moments: after the binding crate and package build and import, before the gates are wired; and at the end, before hand-back. At each, request an adversarial review from Codex (preferably the Astra model) using reviewer subagents, have other subagents triage the findings, and apply the solutions they produce for the valid ones, following the procedure in the review file beside the issues folder. Ask the reviewers: whether the lint policy truly applies to the binding crate; whether the wheel is really stable-ABI and really works on the Python floor; whether stub and module can drift undetected; whether any API beyond the version has leaked in.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] The binding crate is named `transectpy`, is a workspace member built as a native extension, depends on the Rust client crate, shares the workspace version, and uses the stable ABI with a Python 3.11 floor
- [ ] The wheel manifest uses maturin, names the distribution `transectpy`, places the extension as a private module inside the `transectpy` package, and builds from the locked dependency set
- [ ] After a develop build, `import transectpy` succeeds and the package reports a version equal to the workspace version
- [ ] A hand-written stub describes the extension module, a typed marker ships in the package, and stub verification against the built module passes
- [ ] Linting (all rules, with the models' documented exceptions), format check and strict type checking pass over the package, its tests and repository scripts
- [ ] Positive-control fixtures prove the linter and the type checker fail when they should
- [ ] A deliberate unwrap or panic in non-test code of the binding crate makes the clippy recipe fail; evidence quoted in the hand-back, violation not committed
- [ ] Pytest runs against the develop build and asserts the import and version
- [ ] A wheel recipe builds exactly one wheel; a smoke recipe installs it offline into a fresh environment and imports it in isolated mode
- [ ] The smoke also passes on a plain Python 3.11 interpreter, proving the floor
- [ ] Rust test, coverage and mutation recipes exclude the binding crate; the dependency policy, feature and docs recipes still cover it
- [ ] The Python gates are in the ordered check list and the check command ends green
- [ ] CI has a `python` job running the Python gates on Linux and macOS, plus the Python 3.11 floor smoke
- [ ] The adversarial reviews ran at each key moment with Codex reviewer subagents, separate subagents triaged the findings, every valid finding is fixed or handed back as an open point, and the hand-back lists each finding with its verdict and the reviewing model
