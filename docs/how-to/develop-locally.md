---
title: "Develop locally"
kind: "how-to"
audience: ["contributor", "maintainer", "agent"]
canonical_for: ["local_development"]
requires: []
---

# Develop locally

## Prerequisites

| Tool | Why |
| --- | --- |
| `rustup` | Installs the exact toolchain `rust-toolchain.toml` pins, and provides the only cargo the gate accepts. `~/.cargo/bin` must come ahead of any other cargo on `PATH`. |
| `pixi`, at or above `requires-pixi` in `pyproject.toml` | Installs every other tool and the Python environment from `pixi.lock` into the gitignored `.pixi/envs/default`. |
| `just` | The task runner and the only interface. Any `just` launches the recipes; the pinned one in the environment runs every nested call. |
| A C++ compiler | libfuzzer-sys's build script compiles libFuzzer's C++ whenever the fuzz crate builds, which `just check` does: Xcode's command-line tools on macOS, `g++` on Linux. |
| Rosetta 2, on Apple silicon | cargo-fuzz publishes an x86_64 macOS binary only, and `just check` runs `fuzz-build` (`softwareupdate --install-rosetta`). |

Linux x86_64 and macOS arm64 are the platforms the gate runs on
([decision 0007](../decisions/0007-supported-platforms.md)).

## First run

```sh
just initialize
just check
```

`just initialize` installs the pixi environment, the pinned toolchain, the tools pixi
lacks and the Python 3.11 floor interpreter, fetches the lockfiles' dependencies, and, in
the primary checkout only, installs the commit hook. It never stages, commits or pushes.
`just check` must end with `All checks passed and the worktree is unchanged.`

## While working

- Run the narrowest gate first: `just clippy`, `just test`, `just py-test`.
- After changing the binding, `just py-develop` rebuilds the extension in place.
- `just fix` repairs what can be repaired mechanically; `just lint` shows what is left.
- In a secondary git worktree, `just install-hooks` refuses: install hooks once from the
  primary checkout, because every worktree shares one hooks directory.
- Scratch work goes in `ai_tmp/`, which git ignores.

## Before handing back

Run `just check` on a clean worktree and read its last line. A gate that changed a file
fails the run even if every recipe passed.

## Related pages

- [Commands](../reference/commands.md)
- [Troubleshooting](../operations/troubleshooting.md)
