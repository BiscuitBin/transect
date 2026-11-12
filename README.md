# Transect

Transect is an observability tool that captures information about an application, its
runtime and its state, and publishes it so it can be queried.

This repository holds Transect's in-application client: the library a host application
links or imports. It has three crates:

- `libtransect`, the core, where every behaviour of the client will live;
- `transect`, the Rust client API;
- `transectpy`, the Python client, built as the `transectpy` wheel.

It provides no query engine, server or command-line tool.

## Status

This is a scaffold. Each crate exposes one thing, its version, and nothing is published
to crates.io or PyPI. The client's design is not decided yet; its open questions are on
the [open-decisions register](docs/project/open-decisions.md). The quality gate, CI,
handbook and agent contract are in place; the client's behaviour has not started.

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
