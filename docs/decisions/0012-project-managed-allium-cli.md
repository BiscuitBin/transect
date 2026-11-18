---
title: "Decision 0012: A project-managed Allium binary"
kind: "decision"
audience: ["maintainer", "agent"]
canonical_for: ["decision_allium_cli"]
requires: []
---

# Decision 0012: A project-managed Allium binary

Adapted from rove's decision 0010, itself adapted from pachinko's decision 0005 at
`611a86e`. This is a tooling decision. It decides nothing about the client.

## Context

`docs/specs/` holds an Allium specification of the client
([Work with the specifications](../how-to/work-with-the-specs.md)). Something has to
confirm mechanically that it parses and analyses cleanly, or it is read by eye alone.
`allium` is the tool that checks it.

`allium` is a Rust binary published by [`juxt/allium-tools`][upstream]. No lockfile here
can name it: `pixi.lock` pins conda and PyPI packages, and the binary is neither. So
`just lock-check` proves nothing about it, and its pin needs a proof of its own.

Three packages share the name and are not this tool. On PyPI, `allium-cli` is a client
for a blockchain data service. On npm, `allium` is a Gherkin parser. On crates.io,
`allium` is an onion-routing library; the crate that is this tool is `allium-cli`.

## Decision

Install the prebuilt release binary, pinned by version and by SHA-256, into the
gitignored `.tools/bin/`. The `biscuit-games-tooling` package that `pyproject.toml` pins
at a Git tag holds the version, the release URL and the checksum of each supported
artefact. `just install-allium` runs its `bg-install-allium`, and `just check-specs` and
`just analyse-specs` run the result through its `bg-run-allium`. The version that
package pins today is 3.6.1.

Both recipes are gates: the last two entries of `just check`, and hooks in
`.pre-commit-config.yaml` that fire on `docs/specs/` and on `pyproject.toml`, where the
pin lives. `scripts/initialize.sh` and the CI setup action both run
`just install-allium`.

`cargo install allium-cli --locked` would also produce the tool. It is not taken: a
source build costs minutes on every cold runner and verifies nothing about what it
built, and the house installer is the one path that records a version, a URL and a
checksum.

## Consequences

The binary is not in `pixi.lock`, and `just sync` does not install it. A worktree that
has not run `just initialize` fails `just lint` and `just check` until
`just install-allium` puts one there. That is accepted: a gate that skips itself when
its tool is missing asserts nothing.

`just install-allium` is a network recipe, so it needs authorization like the others.
In CI the binary rides in the `.tools` cache, whose key does not name its pin. The
installer checks the version first, so a stale binary is replaced, at the cost of one
small download per run until a tool list next moves the key.

Neither subcommand's exit code is the verdict, so `bg-run-allium` reads the JSON each
prints and asserts an empty `diagnostics` array and an empty `findings` array in every
module. Moving the pin is a release of the tooling package, taken here by moving its
tag and relocking, and every waiver must be verified again when it moves.

Only the four unix targets are supported, which matches
[decision 0007](0007-supported-platforms.md).

## What would reopen this

A distribution channel that `pixi.lock` can name, which would let `just sync` install
the checker and remove the network step from the first run and from CI.

[upstream]: https://github.com/juxt/allium-tools

## Related pages

- [Work with the specifications](../how-to/work-with-the-specs.md)
- [Maintain dependencies](../how-to/maintain-dependencies.md)
- [Quality gates](../reference/quality-gates.md)
