# Transect

Transect captures data from inside running applications as tables, of two kinds: state
tables and time series tables. Once published, those tables can be queried with SQL.

This repository holds Transect's in-application client: the library a host application
links or imports to record its data. It has three crates:

- `libtransect`, the core, where every behaviour of the client will live;
- `transect`, the Rust client API;
- `transectpy`, the Python client, built as the `transectpy` wheel.

It does not hold the collector, which gathers and publishes the tables and lives
elsewhere, and it provides no query engine, server or command-line tool.

## Status

This is a scaffold. Each crate exposes one thing, its version, and nothing is published
to crates.io or PyPI. The places where the ingest queue, the local database, schema
evolution and the data writer will live are documentation-only placeholders. The ingest
queue, the local database format and schema evolution wait on decisions listed in the
[open-decisions register](docs/project/open-decisions.md). The quality gate, CI, handbook
and agent contract are in place; the client's behaviour has not started.

Two rules shape everything the client will do:

- it never raises into or blocks the host application
  ([decision 0001](docs/decisions/0001-never-raise-never-block.md));
- it behaves correctly when the host forks
  ([decision 0002](docs/decisions/0002-fork-safety.md)).

Linux and macOS are supported; Windows is not
([decision 0007](docs/decisions/0007-supported-platforms.md)).

## Quick start

Install the prerequisites listed in
[Develop locally](docs/how-to/develop-locally.md): rustup, pixi and just. Then, from a
clone:

```console
just initialize
just check
```

`just check` ends with `All checks passed and the worktree is unchanged.` The
[clone-to-green tutorial](docs/tutorials/clone-to-green.md) walks through the first run.

## Documentation

- The handbook starts at [docs/README.md](docs/README.md).
- The Rust API reference is built locally: `just doc`, then open
  `target/doc/libtransect/index.html` or `target/doc/transect/index.html`. The Pages
  workflow publishes it from `main` only once the repository is public.
- Agents read [AGENTS.md](AGENTS.md) first.
- Changes are recorded in [CHANGELOG.md](CHANGELOG.md); vulnerabilities are reported as
  [SECURITY.md](SECURITY.md) describes.

## Licence

Apache-2.0; see [LICENSE](LICENSE).
