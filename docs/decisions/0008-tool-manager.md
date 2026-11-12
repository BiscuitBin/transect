---
title: "Decision 0008: pixi, rustup and just as the tool manager"
kind: "decision"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["decision_tool_manager"]
requires: []
---

# Decision 0008: pixi, rustup and just as the tool manager

Carried from alliumpy decision 0006 and pachinko's equivalent.

## Context

Every gate must run the same tool versions on a contributor's machine and in CI, without
a contributor installing them by hand.

## Decision

- **rustup** owns the compiler. `rust-toolchain.toml` pins an exact stable release, and
  `just check-toolchain` refuses any cargo that is not rustup's proxy for that pin, a
  `RUSTUP_TOOLCHAIN` or override that outranks the file, and a `RUSTC` override.
- **pixi** owns every other tool and the Python environment, declared in the root
  `pyproject.toml` (tooling only, not a package) at exact pins and locked in `pixi.lock`.
  Rust is deliberately absent from it.
- **cargo-binstall**, from pixi, installs what conda-forge lacks from `tools.txt` and
  `tools-source.txt` into the gitignored `.tools/`, together with the Python 3.11 floor
  interpreter.
- **just** is the only interface. Every command is a recipe, and `just check` is the
  biscuit-games-tooling project-check runner over the ordered recipe list in
  `pyproject.toml`.

## Consequences

`just initialize` is the one first-run command, and it needs rustup, pixi and just
already installed. Every pin has one owner.

## What would reopen this

conda-forge carrying every remaining tool, which would empty the pin lists.

## Related pages

- [Develop locally](../how-to/develop-locally.md)
- [Commands](../reference/commands.md)
