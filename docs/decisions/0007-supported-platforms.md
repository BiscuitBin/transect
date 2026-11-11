---
title: "Decision 0007: Linux and macOS are the supported platforms"
kind: "decision"
audience: ["user", "contributor", "maintainer", "agent"]
canonical_for: ["decision_supported_platforms"]
requires: []
---

# Decision 0007: Linux and macOS are the supported platforms

## Context

The hosts this client is for run on Linux servers and are developed on macOS. Windows
would double the platform work, and the fork-safety rule
([decision 0002](0002-fork-safety.md)) is about a POSIX process model in the first place.

## Decision

Linux and macOS are supported; Windows is not. Two sets are distinct:

- **Gated:** every pull request runs the gate on x86_64 Linux (`ubuntu-latest`) and
  arm64 macOS (`macos-latest`). The pixi environment is solved for `linux-64` and
  `osx-arm64`, and the Justfile and scripts are POSIX shell.
- **Intended to ship:** glibc and musl Linux on x86_64 and aarch64, and macOS on x86_64
  and arm64, the six targets `deny.toml` resolves dependencies for. Wheels for them are
  stable-ABI (`abi3`) with a Python 3.11 floor. Only the two gated platforms are tested
  today; the others are built and smoke-tested by the release workflow,
  `release-pypi.yml`.

## Consequences

A contributor on Windows works through WSL or a Linux container. A dependency that
appears only on Windows is out of scope for the dependency policy.

## What would reopen this

A host community on Windows large enough to justify it.

## Related pages

- [Decision 0002: Fork safety](0002-fork-safety.md)
- [Develop locally](../how-to/develop-locally.md)
