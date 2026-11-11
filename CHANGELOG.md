# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Every
crate and the `transectpy` wheel share one version
([decision 0006](docs/decisions/0006-single-version.md)), so this one changelog covers
them all. Nothing has been released yet.

## [Unreleased]

### Added

- The three-crate foundation: the `libtransect` core, the `transect` Rust client API and
  the `transectpy` PyO3 binding with its Python package, each exposing only its version.
- Documentation-only placeholders for the ingest queue, the local database, schema
  evolution and the data writer, with the undecided areas on the open-decisions register.
- The read-only `just check` gate on pinned tools, the hook gate, CI on Linux and macOS,
  and a fork test harness for the Python client.
- Weekly advisory, fuzz and mutation-testing workflows, the Pages workflow and Renovate.
- The handbook with its decision records, and the agent contract with its skills.
- Release workflows for PyPI and crates.io, both started by one version tag, and run so
  far only as dry runs.
