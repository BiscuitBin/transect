---
title: "Troubleshooting"
kind: "operations"
audience: ["contributor", "maintainer", "operator", "agent"]
canonical_for: ["troubleshooting"]
requires: []
---

# Troubleshooting

Failures a contributor meets on the way to a green `just check`, what each message
means, and the fix.

## `cargo resolves to …, not rustup's proxy`

`check-toolchain` found a cargo that is not rustup's (from pixi global, Homebrew or a
distribution) first on `PATH`. Put `~/.cargo/bin` ahead of it, or uninstall it.

## `the active toolchain is …; it must be …, selected by rust-toolchain.toml`

`RUSTUP_TOOLCHAIN` or a `rustup override` outranks the pin file. Unset the variable or
run `rustup override unset` in the checkout.

## `RUSTC is set (…)`

A `RUSTC` override makes cargo use another compiler. Unset it.

## `fuzz-build` fails with `Bad CPU type` on Apple silicon

cargo-fuzz's macOS binary is x86_64. Install Rosetta 2 with
`softwareupdate --install-rosetta`.

## `install-hooks: this is a secondary worktree`

Hooks are shared by every worktree, so they are installed once, from the primary
checkout. Run `just install-hooks` there.

## `… changed the worktree; checks must be read-only`

A recipe wrote a file that git can see. The run names it under `changed:`. A generated
file belongs under an ignored directory; a tracked file a gate rewrote is a bug in that
recipe.

## `wheel-smoke-floor` cannot find Python 3.11

The floor interpreter lives in `.tools/python`. Run `just install-tools`.

## Related pages

- [Develop locally](../how-to/develop-locally.md)
- [Commands](../reference/commands.md)
