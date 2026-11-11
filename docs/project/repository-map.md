---
title: "Repository map"
kind: "project"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["repository_layout"]
requires: []
---

# Repository map

Where everything lives. Paths are relative to the repository root.

## Code

| Path | What it is |
| --- | --- |
| `crates/libtransect/` | The core crate. `src/lib.rs` holds `version()`; `src/ingest_queue.rs`, `src/local_database.rs`, `src/schema_evolution.rs` and `src/data_writer.rs` are documentation-only placeholders; `benches/version.rs` is the divan benchmark. |
| `crates/transect/` | The Rust client API crate; `src/lib.rs` holds `version()`. |
| `crates/transectpy/` | The PyO3 binding crate (`src/lib.rs`), its maturin manifest (`pyproject.toml`), the Python package under `python/transectpy/` (with the hand-written stub `_transectpy.pyi` and `py.typed`), and the Python tests under `tests/`. |
| `fuzz/` | The fuzz crate, outside the workspace, with its own `Cargo.lock` and the `smoke` target. |
| `scripts/` | `initialize.sh`, `version_check.py` and `check_undecided.py`. |
| `tests/` | The scripts' tests (`tests/scripts/`), the lint and type-check positive-control fixtures (`tests/fixtures/py-lint-violation/`) and the installed-wheel smoke (`tests/fixtures/smoke/`). |

## Configuration

| Path | What it configures |
| --- | --- |
| `Cargo.toml`, `Cargo.lock` | The workspace, its shared version, lint policy and dependency ranges, and the pin. |
| `rust-toolchain.toml` | The exact Rust release. |
| `pyproject.toml`, `pixi.lock` | The pixi tool environment and the ordered gate list for `just check`; not a Python package. |
| `tools.txt`, `tools-source.txt` | Tools conda-forge lacks, installed into `.tools/`. |
| `Justfile` | Every command. |
| `clippy.toml`, `rustfmt.toml`, `taplo.toml`, `rustqual.toml`, `.config/nextest.toml` | The Rust gates. |
| `deny.toml` | The dependency policy. |
| `ruff.toml`, `mypy.ini` | The Python gates. |
| `.pre-commit-config.yaml`, `.pre-commit-fix.yaml` | The hook gate and the fixers. |
| `.markdownlint-cli2.jsonc`, `_typos.toml`, `lychee.toml`, `.editorconfig` | The document and text checks. |
| `.github/actions/setup/`, `.github/workflows/ci.yml` | The CI setup action and workflow. |

## Documents

| Path | What it is |
| --- | --- |
| `docs/` | This handbook; `docs/manifest.yml` registers every page. |
| `README.md`, `CHANGELOG.md`, `AGENTS.md`, `CLAUDE.md` | Entry files; placeholders until later tickets replace them. |
| `.scratch/` | Tracked bootstrap tickets; local ticket scratch is otherwise gitignored. |

## Generated and local, never committed

`target/`, `dist/`, `.pixi/`, `.tools/`, `ai_tmp/` (agent scratch), `mutants.out*/` and the
fuzz corpora are gitignored; `.gitignore` gives each a reason.

## Related pages

- [Architecture](../explanation/architecture.md)
- [Commands](../reference/commands.md)
